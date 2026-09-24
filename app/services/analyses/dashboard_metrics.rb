# frozen_string_literal: true

module Analyses
  # Calcule et assigne les ivars du dashboard selon l'onglet (hors controller).
  class DashboardMetrics
    def initialize(controller)
      @c = controller
    end

    def assign_tab!(vue, filter_params:, stripe_totals:)
      vue = DashboardVisibility.normalize_vue(vue)
      ivar_set(:timeline_grain, TimelineBuckets.grain(datedebut, datefin))

      case vue
      when "synthese"
        assign_commande_metrics
        assign_article_metrics
        assign_ca_metrics(stripe_totals, datedebut, datefin)
        assign_catalog_stats
        assign_profile_stats(datedebut, datefin, stripe_totals, filter_params)
        assign_synthese_top_profile_from_stats
      when "ca"
        assign_commande_metrics
        assign_article_metrics
        assign_ca_metrics(stripe_totals, datedebut, datefin)
        assign_transaction_metrics(stripe_totals, datedebut, datefin)
      when "catalogue"
        assign_article_metrics
        assign_catalog_stats
      when "equipe"
        assign_profile_stats(datedebut, datefin, stripe_totals, filter_params)
      end
    end

    private

    def timeline_grain
      ivar(:timeline_grain) || :day
    end

    def datedebut
      ivar(:datedebut)
    end

    def datefin
      ivar(:datefin)
    end

    def commandes_filtres
      ivar(:commandesFiltres)
    end

    def articles_filtres
      ivar(:articlesFiltres)
    end

    def sous_articles_filtres
      ivar(:sousArticlesFiltres)
    end

    def paiements_filtres
      ivar(:paiementsFiltres)
    end

    def remboursements_boutique_filtres
      ivar(:remboursementsBoutiqueFiltres) || AvoirRemb.none
    end

    def stripe_payments_paid_filtres
      ivar(:stripePaymentsPaidFiltres)
    end

    def stripe_payment_items_filtres
      ivar(:stripePaymentItemsFiltres)
    end

    def line_metrics
      ivar(:line_metrics)
    end

    def total_stripe_eur
      ivar(:total_stripe_eur)
    end

    def analyses_ca_mode
      ivar(:analyses_ca_mode)
    end

    def product_dimension_filtered
      ivar(:product_dimension_filtered)
    end

    def ivar(name)
      @c.instance_variable_get(:"@#{name}")
    end

    def ivar_set(name, value)
      @c.instance_variable_set(:"@#{name}", value)
    end

    def assign_commande_metrics
      ivar_set(:nbTotal, commandes_filtres.count)
      ivar_set(:nbRetire, commandes_filtres.retire.count)
      ivar_set(:nbNonRetire, commandes_filtres.non_retire.count)
      ivar_set(:nbRendu, commandes_filtres.rendu.count)
      ivar_set(:nbDevisPeriode, devis_dans_periode(datedebut, datefin).count)

      if timeline_grain == :hour
        rows = commandes_filtres.pluck(:created_at).map { |at| [at, 1] }
        ivar_set(:groupedByDate, TimelineBuckets.group_times(rows, grain: :hour).transform_values(&:to_i))
      else
        grouped_by_date = commandes_filtres.group("DATE(created_at)").order("DATE(commandes.created_at)").count("created_at")
        ivar_set(:groupedByDate, grouped_by_date.transform_keys { |date| TimelineBuckets.normalize_day_key(date) })
      end
    end

    def assign_article_metrics
      # Nb d'articles = sommes des quantités (ligne × qté), pas le count de lignes.
      ivar_set(:nbTotalArticles, line_metrics.quantites)
      ivar_set(:nbLoc, line_metrics.loc_quantites)
      ivar_set(:nbVente, line_metrics.vente_quantites)
      ivar_set(:caLocArticles, line_metrics.loc_ca_lignes)
      ivar_set(:caVenteArticles, line_metrics.vente_ca_lignes)

      if timeline_grain == :hour
        ivar_set(:groupedByDateArticles, line_metrics.quantites_for_timeline(:hour))
      else
        ivar_set(:groupedByDateArticles, line_metrics.quantites_by_day.transform_keys { |date|
          TimelineBuckets.normalize_day_key(date)
        })
      end
    end

    def assign_transaction_metrics(stripe_totals, datedebut, datefin)
      total_loc = articles_filtres.location_only.sum(:prix).to_d + sous_articles_filtres.location_only.sum(:prix).to_d
      articles_vente_hors_eshop = articles_filtres.where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      sous_vente_hors_eshop = sous_articles_filtres.joins(article: :commande).merge(Commande.hors_devis).where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
      total_vente = articles_vente_hors_eshop + sous_vente_hors_eshop + total_stripe_eur

      ivar_set(:totalTransactionsLoc, total_loc)
      ivar_set(:totalTransactionsVente, total_vente)
      ivar_set(:totalTransactions, total_loc + total_vente)

      articles_timeline = articles_filtres.where(commandes: { eshop: [false, nil] })
      if timeline_grain == :hour
        article_rows = articles_timeline.pluck(:created_at, :total)
        ivar_set(
          :groupedByDateTransactions,
          merge_timeline_hashes(
            TimelineBuckets.group_times(article_rows, grain: :hour),
            stripe_totals.grouped_for_timeline(:hour),
            eshop_remboursements_for_timeline_neg(datedebut, datefin)
          )
        )
      else
        grouped_articles_jour = articles_timeline.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
        ivar_set(
          :groupedByDateTransactions,
          merge_timeline_hashes(
            grouped_articles_jour,
            stripe_totals.grouped_by_day_eur,
            eshop_remboursements_by_day_neg(datedebut, datefin)
          )
        )
      end
    end

    def assign_ca_metrics(stripe_totals, datedebut, datefin)
      if analyses_ca_mode == :lignes
        assign_ca_metrics_from_lines(stripe_totals, datedebut, datefin)
      else
        assign_ca_metrics_from_paiements(stripe_totals, datedebut, datefin)
      end
    end

    def assign_ca_metrics_from_paiements(stripe_totals, datedebut, datefin)
      by_moyen = paiements_filtres.only_prix.group(:moyen).sum(:montant)
      remb_by_moyen = remboursements_boutique_filtres.group(:moyen).sum(:montant)
      remb_total = remb_by_moyen.values.sum.to_d

      ivar_set(:totalPrixCaCb, by_moyen.fetch("carte bleue", 0).to_d - remb_by_moyen.fetch("carte bleue", 0).to_d)
      ivar_set(:totalPrixCaEspeces, by_moyen.fetch("espèces", 0).to_d - remb_by_moyen.fetch("espèces", 0).to_d)
      ivar_set(:totalPrixCaCheque, by_moyen.fetch("chèque", 0).to_d - remb_by_moyen.fetch("chèque", 0).to_d)
      ivar_set(:totalPrixCaVirement, by_moyen.fetch("virement", 0).to_d - remb_by_moyen.fetch("virement", 0).to_d)
      ivar_set(:totalPrixCaStripe, total_stripe_eur)
      boutique = ivar(:totalPrixCaCb) + ivar(:totalPrixCaEspeces) + ivar(:totalPrixCaCheque) + ivar(:totalPrixCaVirement)
      ivar_set(:totalPrixCaBoutique, boutique)
      ivar_set(:totalPrixCa, boutique + total_stripe_eur)
      ivar_set(:totalCa, paiements_filtres.sum(:montant).to_d - remb_total + total_stripe_eur)

      if timeline_grain == :hour
        # Jour métier = custom_date (déjà filtré) ; heure ops = created_at.
        boutique = TimelineBuckets.group_times(
          paiements_filtres.only_prix.pluck(:created_at, :montant),
          grain: :hour
        )
        boutique_remb_neg = boutique_remboursements_for_timeline_neg
        remb_neg = eshop_remboursements_for_timeline_neg(datedebut, datefin)
        stripe = stripe_totals.grouped_for_timeline(:hour)
      else
        boutique = paiements_filtres.only_prix.group(:custom_date).order(:custom_date).sum(:montant)
        boutique_remb_neg = boutique_remboursements_by_day_neg
        remb_neg = eshop_remboursements_by_day_neg(datedebut, datefin)
        stripe = stripe_totals.grouped_by_day_eur
      end

      ivar_set(:groupedByDateCaBoutique, merge_timeline_hashes(boutique, boutique_remb_neg))
      ivar_set(:groupedByDateCaEshop, merge_timeline_hashes(stripe, remb_neg))
      ivar_set(:groupedByDateCa, merge_timeline_hashes(boutique, boutique_remb_neg, stripe, remb_neg))
    end

    def assign_ca_metrics_from_lines(stripe_totals, datedebut, datefin)
      boutique_lines = articles_filtres.where(commandes: { eshop: [false, nil] }).sum(:prix).to_d +
                       sous_articles_filtres.joins(article: :commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
      ivar_set(:totalPrixCaCb, 0.to_d)
      ivar_set(:totalPrixCaEspeces, 0.to_d)
      ivar_set(:totalPrixCaCheque, 0.to_d)
      ivar_set(:totalPrixCaVirement, 0.to_d)
      ivar_set(:totalPrixCaStripe, total_stripe_eur)
      ivar_set(:totalPrixCaBoutique, boutique_lines)
      ivar_set(:totalPrixCa, boutique_lines + total_stripe_eur)
      ivar_set(:totalCa, boutique_lines + total_stripe_eur)

      boutique_scope = articles_filtres.where(commandes: { eshop: [false, nil] })
      if timeline_grain == :hour
        boutique = TimelineBuckets.group_times(boutique_scope.pluck(:created_at, :total), grain: :hour)
        remb_neg = eshop_remboursements_for_timeline_neg(datedebut, datefin)
        stripe = stripe_totals.grouped_for_timeline(:hour)
      else
        boutique = boutique_scope.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
        remb_neg = eshop_remboursements_by_day_neg(datedebut, datefin)
        stripe = stripe_totals.grouped_by_day_eur
      end

      ivar_set(:groupedByDateCaBoutique, merge_timeline_hashes(boutique))
      ivar_set(:groupedByDateCaEshop, merge_timeline_hashes(stripe, remb_neg))
      ivar_set(:groupedByDateCa, merge_timeline_hashes(boutique, stripe, remb_neg))
    end

    def assign_profile_stats(datedebut, datefin, stripe_totals, filter_params)
      profiles = Profile.for_analyses_charts.order(:prenom, :nom)
      profiles = profiles.where(id: filter_params[:filter_profile]) if filter_params[:filter_profile].present?

      commandes_devis = if datedebut.present? && datefin.present?
                          Commande.est_devis.filtredatedebut(datedebut).filtredatefin(datefin)
                        else
                          Commande.est_devis.all
                        end

      ivar_set(:stats_par_profile, profiles.map.with_index do |profile, index|
        row = profile_kpi_row(profile, stripe_totals)
        commande_ids = row[:commande_ids]
        row.merge(
          devis: commandes_devis.where(profile_id: profile.id).count,
          articles: profile_articles_lignes_count(commande_ids),
          transactions: profile_transactions(commande_ids, stripe_totals),
          couleur: ChartPayloads.equipe_pastel_color(index),
          ca_by_day: profile_ca_by_day(profile.id, commande_ids, datedebut, datefin)
        ).except(:commande_ids)
      end)
    end

    def profile_transactions(commandes_ids, stripe_totals)
      return 0.to_d if commandes_ids.blank?

      loc = articles_filtres.location_only.where(commande_id: commandes_ids).sum(:prix).to_d +
            sous_articles_filtres.location_only.where(articles: { commande_id: commandes_ids }).sum(:prix).to_d
      vente_articles = articles_filtres
                         .joins(:commande)
                         .where(commande_id: commandes_ids, commandes: { eshop: [false, nil] })
                         .vente_only
                         .sum(:prix).to_d
      vente_sous = sous_articles_filtres
                     .vente_only
                     .joins(article: :commande)
                     .where(articles: { commande_id: commandes_ids }, commandes: { eshop: [false, nil] })
                     .sum(:prix).to_d

      loc + vente_articles + vente_sous + stripe_totals.total_eur(commande_ids: commandes_ids)
    end

    def assign_synthese_top_profile_from_stats
      top = Array(ivar(:stats_par_profile)).max_by { |row| row[:ca].to_d }
      ivar_set(
        :synthese_top_profile,
        top&.slice(:profile, :profile_id, :commandes, :ca, :articles)
      )
    end

    def profile_kpi_row(profile, stripe_totals)
      commandes = commandes_filtres.where(profile_id: profile.id)
      commandes_ids = commandes.pluck(:id)
      ca_paiements = if analyses_ca_mode == :lignes
                       ligne_ca_for_commandes(commandes_ids)
                     else
                       paiements_filtres.only_prix
                                        .joins(:commande)
                                        .where(commandes: { profile_id: profile.id })
                                        .sum(:montant).to_d -
                       remboursements_boutique_filtres
                         .merge(Commande.where(profile_id: profile.id))
                         .sum(:montant).to_d
                     end
      stripe_ids = stripe_payments_paid_filtres.where(
        commande_id: Commande.where(profile_id: profile.id).select(:id)
      ).distinct.pluck(:commande_id)
      ca = ca_paiements + stripe_totals.total_eur(commande_ids: stripe_ids)
      label = profile.full_name.presence || profile.prenom.presence || "Profil ##{profile.id}"

      {
        profile: label,
        profile_id: profile.id,
        commandes: commandes.count,
        ca: ca,
        commande_ids: commandes_ids
      }
    end

    def profile_articles_lignes_count(commandes_ids)
      return 0 if commandes_ids.blank?

      stripe_scope =
        if stripe_payment_items_filtres.nil?
          StripePaymentItem.none
        else
          stripe_payment_items_filtres.joins(:stripe_payment).where(stripe_payments: { commande_id: commandes_ids })
        end

      LineMetrics.new(
        articles_scope: articles_filtres.where(commande_id: commandes_ids),
        stripe_items_scope: stripe_scope
      ).quantites
    end

    def profile_ca_by_day(profile_id, commandes_ids, datedebut, datefin)
      stripe_commande_scope =
        if analyses_ca_mode == :lignes
          commandes_ids
        else
          Commande.where(profile_id: profile_id).select(:id)
        end

      if timeline_grain == :hour
        boutique =
          if analyses_ca_mode == :lignes
            return {} if commandes_ids.blank?

            TimelineBuckets.group_times(
              articles_filtres
                .where(commande_id: commandes_ids)
                .joins(:commande)
                .where(commandes: { eshop: [false, nil] })
                .pluck(:created_at, :prix),
              grain: :hour
            )
          else
            TimelineBuckets.group_times(
              paiements_filtres.only_prix
                .joins(:commande)
                .where(commandes: { profile_id: profile_id })
                .pluck("paiement_recus.created_at", "paiement_recus.montant"),
              grain: :hour
            )
          end

        stripe = TimelineBuckets.group_times(
          stripe_payments_paid_filtres
            .where(commande_id: stripe_commande_scope)
            .pluck(:created_at, :amount)
            .map { |at, cents| [at, cents.to_d / 100] },
          grain: :hour
        )

        remb = TimelineBuckets.group_times(
          eshop_remboursements_scope(datedebut, datefin, product_dimension_filtered: false)
            .where(commande_id: stripe_commande_scope)
            .pluck(:created_at, :montant)
            .map { |at, montant| [at, -montant.to_d] },
          grain: :hour
        )

        boutique_remb =
          if analyses_ca_mode == :lignes
            {}
          else
            TimelineBuckets.group_times(
              remboursements_boutique_filtres
                .merge(Commande.where(profile_id: profile_id))
                .pluck("avoir_rembs.created_at", "avoir_rembs.montant")
                .map { |at, montant| [at, -montant.to_d] },
              grain: :hour
            )
          end

        merge_timeline_hashes(boutique, boutique_remb, stripe, remb)
      else
        boutique =
          if analyses_ca_mode == :lignes
            return {} if commandes_ids.blank?

            articles_filtres
              .where(commande_id: commandes_ids)
              .joins(:commande)
              .where(commandes: { eshop: [false, nil] })
              .group("DATE(articles.created_at)")
              .sum(:prix)
          else
            paiements_filtres.only_prix
              .joins(:commande)
              .where(commandes: { profile_id: profile_id })
              .group(:custom_date)
              .sum(:montant)
          end

        stripe = stripe_payments_paid_filtres
                   .where(commande_id: stripe_commande_scope)
                   .group("DATE(stripe_payments.created_at)")
                   .sum(:amount)
                   .transform_values { |cents| cents.to_d / 100 }

        remb = eshop_remboursements_scope(
                 datedebut,
                 datefin,
                 product_dimension_filtered: false
               )
                 .where(commande_id: stripe_commande_scope)
                 .group("COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at))")
                 .sum(:montant)
                 .transform_values { |montant| -montant.to_d }

        boutique_remb =
          if analyses_ca_mode == :lignes
            {}
          else
            remboursements_boutique_filtres
              .merge(Commande.where(profile_id: profile_id))
              .group(:custom_date)
              .sum(:montant)
              .transform_values { |montant| -montant.to_d }
          end

        merge_timeline_hashes(boutique, boutique_remb, stripe, remb)
      end
    end

    def ligne_ca_for_commandes(commandes_ids)
      articles = articles_filtres.where(commande_id: commandes_ids).joins(:commande).where(commandes: { eshop: [false, nil] }).sum(:prix).to_d
      sous = sous_articles_filtres.joins(article: :commande).where(commandes: { id: commandes_ids, eshop: [false, nil] }).sum(:prix).to_d
      articles + sous
    end

    def assign_catalog_stats
      stats = CatalogStats.call(
        articles_filtres,
        stripe_items_scope: stripe_payment_items_filtres
      )
      ivar_set(:catalog_top_products, stats[:top_products])
      ivar_set(:catalog_top_products_by_qty, stats[:top_products_by_qty])
      ivar_set(:catalog_top_products_by_ca, stats[:top_products_by_ca])
      ivar_set(:catalog_by_type, stats[:by_type])
      ivar_set(:catalog_by_type_by_ca, stats[:by_type_by_ca])
      ivar_set(:catalog_by_categorie, stats[:by_categorie])
      ivar_set(:catalog_by_categorie_by_ca, stats[:by_categorie_by_ca])
      ivar_set(:catalog_categorie_notice, stats[:categorie_attribution_notice])
    end

    def eshop_remboursements_scope(datedebut, datefin, product_dimension_filtered: false, stripe_scope: nil)
      rel = AvoirRemb.remb_only.joins(:commande).where(commandes: { eshop: true })
      if datedebut.present? && datefin.present?
        rel = rel.where(
          "COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at)) BETWEEN ? AND ?",
          datedebut.to_date,
          datefin.to_date
        )
      end
      if product_dimension_filtered && stripe_scope
        rel = rel.where(commande_id: stripe_scope.select(:commande_id))
      end
      rel
    end

    def boutique_remboursements_by_day_neg
      memo = ivar(:boutique_remboursements_by_day_neg)
      return memo if memo

      value = remboursements_boutique_filtres
                .group(:custom_date)
                .sum(:montant)
                .transform_values { |montant| -montant.to_d }
      ivar_set(:boutique_remboursements_by_day_neg, value)
      value
    end

    def boutique_remboursements_for_timeline_neg
      memo = ivar(:boutique_remboursements_for_timeline_neg)
      return memo if memo

      rows = remboursements_boutique_filtres
               .pluck(:created_at, :montant)
               .map { |at, montant| [at, -montant.to_d] }
      value = TimelineBuckets.group_times(rows, grain: timeline_grain)
      ivar_set(:boutique_remboursements_for_timeline_neg, value)
      value
    end

    def eshop_remboursements_grouped_by_day(datedebut, datefin, product_dimension_filtered: false, stripe_scope: nil)
      eshop_remboursements_scope(datedebut, datefin, product_dimension_filtered: product_dimension_filtered, stripe_scope: stripe_scope)
        .group("COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at))")
        .sum(:montant)
    end

    def eshop_remboursements_by_day_neg(datedebut, datefin)
      memo = ivar(:eshop_remboursements_by_day_neg)
      return memo if memo

      value = eshop_remboursements_grouped_by_day(
        datedebut,
        datefin,
        product_dimension_filtered: product_dimension_filtered,
        stripe_scope: stripe_payments_paid_filtres
      ).transform_values { |montant| -montant.to_d }
      ivar_set(:eshop_remboursements_by_day_neg, value)
      value
    end

    # Grain heure : bucketter created_at (ops) ; le scope date reste custom_date COALESCE.
    def eshop_remboursements_for_timeline_neg(datedebut, datefin)
      memo = ivar(:eshop_remboursements_for_timeline_neg)
      return memo if memo

      rows = eshop_remboursements_scope(
        datedebut,
        datefin,
        product_dimension_filtered: product_dimension_filtered,
        stripe_scope: stripe_payments_paid_filtres
      ).pluck(:created_at, :montant).map { |at, montant| [at, -montant.to_d] }

      value = TimelineBuckets.group_times(rows, grain: timeline_grain)
      ivar_set(:eshop_remboursements_for_timeline_neg, value)
      value
    end

    def devis_dans_periode(datedebut, datefin)
      scope = Commande.est_devis
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      scope
    end

    # Fusion grain-aware : clés jour "%d/%m/%Y" ou heure "10h".
    def merge_timeline_hashes(*hashes)
      grain = timeline_grain
      merged = Hash.new(0.to_d)
      hashes.each do |h|
        next if h.blank?

        h.each do |key, amount|
          label = if grain == :hour
                    key.to_s
                  else
                    TimelineBuckets.normalize_day_key(key)
                  end
          merged[label] += amount.to_d
        end
      end
      TimelineBuckets.sort_hash(merged, grain: grain)
    end

    # Alias conservé pour d’éventuels callers / specs.
    def merge_grouped_by_day(*hashes)
      merge_timeline_hashes(*hashes)
    end
  end
end
