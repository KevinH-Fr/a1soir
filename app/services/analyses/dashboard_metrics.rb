# frozen_string_literal: true

module Analyses
  # Calcule et assigne les ivars du dashboard selon l'onglet (hors controller).
  class DashboardMetrics
    def initialize(controller)
      @c = controller
    end

    def assign_tab!(vue, filter_params:, stripe_totals:)
      vue = DashboardVisibility.normalize_vue(vue)

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

      grouped_by_date = commandes_filtres.group("DATE(created_at)").order("DATE(commandes.created_at)").count("created_at")
      ivar_set(:groupedByDate, grouped_by_date.transform_keys do |date|
        I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
      end)
    end

    def assign_article_metrics
      ivar_set(:nbTotalArticles, line_metrics.lignes_count)
      ivar_set(:nbLoc, line_metrics.loc_lignes_count)
      ivar_set(:nbVente, line_metrics.vente_lignes_count)
      ivar_set(:caLocArticles, line_metrics.loc_ca_lignes)
      ivar_set(:caVenteArticles, line_metrics.vente_ca_lignes)

      ivar_set(:groupedByDateArticles, line_metrics.quantites_by_day.transform_keys do |date|
        I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
      end)
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
      grouped_articles_jour = articles_timeline.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
      ivar_set(
        :groupedByDateTransactions,
        merge_grouped_by_day(
          grouped_articles_jour,
          stripe_totals.grouped_by_day_eur,
          eshop_remboursements_by_day_neg(datedebut, datefin)
        )
      )
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
      ivar_set(:totalPrixCaCb, by_moyen.fetch("carte bleue", 0).to_d)
      ivar_set(:totalPrixCaEspeces, by_moyen.fetch("espèces", 0).to_d)
      ivar_set(:totalPrixCaCheque, by_moyen.fetch("chèque", 0).to_d)
      ivar_set(:totalPrixCaVirement, by_moyen.fetch("virement", 0).to_d)
      ivar_set(:totalPrixCaStripe, total_stripe_eur)
      boutique = ivar(:totalPrixCaCb) + ivar(:totalPrixCaEspeces) + ivar(:totalPrixCaCheque) + ivar(:totalPrixCaVirement)
      ivar_set(:totalPrixCaBoutique, boutique)
      ivar_set(:totalPrixCa, boutique + total_stripe_eur)
      ivar_set(:totalCa, paiements_filtres.sum(:montant).to_d + total_stripe_eur)

      grouped_by_date_ca_paiements = paiements_filtres.only_prix
                                                    .group("DATE(created_at)")
                                                    .order("DATE(paiement_recus.created_at)")
                                                    .sum(:montant)
      remb_neg = eshop_remboursements_by_day_neg(datedebut, datefin)
      ivar_set(:groupedByDateCaBoutique, merge_grouped_by_day(grouped_by_date_ca_paiements))
      ivar_set(:groupedByDateCaEshop, merge_grouped_by_day(stripe_totals.grouped_by_day_eur, remb_neg))
      ivar_set(
        :groupedByDateCa,
        merge_grouped_by_day(
          grouped_by_date_ca_paiements,
          stripe_totals.grouped_by_day_eur,
          remb_neg
        )
      )
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

      grouped_articles_jour = articles_filtres.where(commandes: { eshop: [false, nil] }).group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
      remb_neg = eshop_remboursements_by_day_neg(datedebut, datefin)
      ivar_set(:groupedByDateCaBoutique, merge_grouped_by_day(grouped_articles_jour))
      ivar_set(:groupedByDateCaEshop, merge_grouped_by_day(stripe_totals.grouped_by_day_eur, remb_neg))
      ivar_set(
        :groupedByDateCa,
        merge_grouped_by_day(
          grouped_articles_jour,
          stripe_totals.grouped_by_day_eur,
          remb_neg
        )
      )
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
        row.merge(
          devis: commandes_devis.where(profile_id: profile.id).count,
          articles: profile_articles_lignes_count(row[:commande_ids]),
          transactions: profile_transactions(row[:commande_ids], stripe_totals),
          couleur: ChartPayloads.equipe_pastel_color(index),
          ca_by_day: profile_ca_by_day(row[:commande_ids], datedebut, datefin)
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
                       paiements_filtres.only_prix.where(commande_id: commandes_ids).sum(:montant).to_d
                     end
      ca = ca_paiements + stripe_totals.total_eur(commande_ids: commandes_ids)
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
      ).lignes_count
    end

    def profile_ca_by_day(commandes_ids, datedebut, datefin)
      return {} if commandes_ids.blank?

      boutique =
        if analyses_ca_mode == :lignes
          articles_filtres
            .where(commande_id: commandes_ids)
            .joins(:commande)
            .where(commandes: { eshop: [false, nil] })
            .group("DATE(articles.created_at)")
            .sum(:prix)
        else
          paiements_filtres.only_prix
            .where(commande_id: commandes_ids)
            .group("DATE(paiement_recus.created_at)")
            .sum(:montant)
        end

      stripe = stripe_payments_paid_filtres
                 .where(commande_id: commandes_ids)
                 .group("DATE(stripe_payments.created_at)")
                 .sum(:amount)
                 .transform_values { |cents| cents.to_d / 100 }

      remb = eshop_remboursements_scope(
               datedebut,
               datefin,
               product_dimension_filtered: false
             )
               .where(commande_id: commandes_ids)
               .group("COALESCE(avoir_rembs.custom_date, DATE(avoir_rembs.created_at))")
               .sum(:montant)
               .transform_values { |montant| -montant.to_d }

      merge_grouped_by_day(boutique, stripe, remb)
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
      ivar_set(:catalog_by_type, stats[:by_type])
      ivar_set(:catalog_by_categorie, stats[:by_categorie])
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

    def devis_dans_periode(datedebut, datefin)
      scope = Commande.est_devis
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      scope
    end

    def merge_grouped_by_day(*hashes)
      merged = Hash.new(0.to_d)
      hashes.each do |h|
        next if h.blank?

        h.each do |date_key, amount|
          label = I18n.l(Date.parse(date_key.to_s), format: "%d/%m/%Y")
          merged[label] += amount.to_d
        end
      end
      merged.sort_by { |k, _| Date.strptime(k, "%d/%m/%Y") }.to_h
    end
  end
end
