class Admin::AnalysesController < Admin::ApplicationController

  #before_action :authenticate_admin!

  def index
    datedebut = DateTime.parse(params[:debut]) if params[:debut].present?
    datefin = DateTime.parse(params[:fin]) if params[:fin].present?
    @datedebut = DateTime.parse(params[:debut]) if params[:debut].present?
    @datefin = DateTime.parse(params[:fin]) if params[:fin].present?

    if datedebut.present? && datefin.present?
      @commandesFiltres = Commande.hors_devis.filtredatedebut(datedebut).filtredatefin(datefin)
      @articlesFiltres = Article.joins(:commande).merge(Commande.hors_devis).filtredatedebut(datedebut).filtredatefin(datefin)
      @sousArticlesFiltres = Sousarticle.filtredatedebut(datedebut).filtredatefin(datefin)
      @paiementsFiltres = PaiementRecu.filtredatedebut(datedebut).filtredatefin(datefin)
      @stripePaymentsPaidFiltres = StripePayment.paid.filtredatedebut(datedebut).filtredatefin(datefin)
    else
      @commandesFiltres = Commande.hors_devis.all
      @articlesFiltres = Article.joins(:commande).merge(Commande.hors_devis).all
      @sousArticlesFiltres = Sousarticle.all
      @paiementsFiltres = PaiementRecu.all
      @stripePaymentsPaidFiltres = StripePayment.paid.all
    end

    @total_stripe_eur = stripe_amount_eur(@stripePaymentsPaidFiltres)

    # commandes :
    @nbTotal = @commandesFiltres.count
    @nbRetire = @commandesFiltres.retire.count
    @nbNonRetire = @commandesFiltres.non_retire.count
    @nbRendu = @commandesFiltres.rendu.count

    groupedByDate = @commandesFiltres.group("DATE(created_at)").order("DATE(commandes.created_at)").count("created_at")
    @groupedByDate = groupedByDate.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
    end

    # articles :
    @nbTotalArticles = @articlesFiltres.count
    @nbLoc = @articlesFiltres.location_only.count
    @nbVente = @articlesFiltres.vente_only.count

    groupedByDateArticles = @articlesFiltres.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("quantite")
    @groupedByDateArticles = groupedByDateArticles.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: "%d/%m/%Y")
    end

    # transactions : location / vente (prix articles + sous-articles). Vente inclut l’e-shop via Stripe
    # (les lignes article des commandes eshop sont exclues du cumul vente pour éviter le double comptage).
    @totalTransactionsLoc = @articlesFiltres.location_only.sum(:prix).to_d + @sousArticlesFiltres.location_only.sum(:prix).to_d
    articles_vente_hors_eshop = @articlesFiltres.where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
    sous_vente_hors_eshop = @sousArticlesFiltres.joins(article: :commande).merge(Commande.hors_devis).where(commandes: { eshop: [false, nil] }).vente_only.sum(:prix).to_d
    @totalTransactionsVente = articles_vente_hors_eshop + sous_vente_hors_eshop + @total_stripe_eur
    @totalTransactions = @totalTransactionsLoc + @totalTransactionsVente

    articles_timeline = @articlesFiltres.where(commandes: { eshop: [false, nil] })
    grouped_articles_jour = articles_timeline.group("DATE(articles.created_at)").order("DATE(articles.created_at)").sum("total")
    grouped_stripe_jour = @stripePaymentsPaidFiltres.group("DATE(stripe_payments.created_at)").order("DATE(stripe_payments.created_at)").sum(:amount)
    grouped_stripe_jour_eur = grouped_stripe_jour.transform_values { |cents| cents.to_d / 100 }
    @groupedByDateTransactions = merge_grouped_by_day(grouped_articles_jour, grouped_stripe_jour_eur)

    # CA (prix boutique + Stripe comme moyen de paiement distinct)
    @totalPrixCaCb = @paiementsFiltres.only_prix.only_cb.sum(:montant).to_d
    @totalPrixCaEspeces = @paiementsFiltres.only_prix.only_espece.sum(:montant).to_d
    @totalPrixCaCheque = @paiementsFiltres.only_prix.only_cheque.sum(:montant).to_d
    @totalPrixCaVirement = @paiementsFiltres.only_prix.only_virement.sum(:montant).to_d
    @totalPrixCaStripe = @total_stripe_eur
    @totalPrixCaBoutique = @totalPrixCaCb + @totalPrixCaEspeces + @totalPrixCaCheque + @totalPrixCaVirement
    @totalPrixCa = @totalPrixCaBoutique + @totalPrixCaStripe

    @totalCa = @paiementsFiltres.sum(:montant).to_d + @total_stripe_eur

    groupedByDateCaPaiements = @paiementsFiltres.group("DATE(created_at)").order("DATE(paiement_recus.created_at)").sum(:montant)
    @groupedByDateCa = merge_grouped_by_day(groupedByDateCaPaiements, grouped_stripe_jour_eur)

    # Une ligne par profil : CA = paiements boutique (PaiementRecu) + Stripe rattachés aux commandes du profil.
    base_r, base_g, base_b = 208, 77, 123
    target_r, target_g, target_b = 245, 190, 210

    profiles = Profile.includes(commandes: [:paiement_recus, :articles])
    total = profiles.size

    if datedebut.present? && datefin.present?
      commandesDevis = Commande.est_devis.filtredatedebut(datedebut).filtredatefin(datefin)
    else
      commandesDevis = Commande.est_devis.all
    end

    @stats_par_profile = profiles.map.with_index do |profile, index|
      commandes = @commandesFiltres.where(profile_id: profile.id)
      commandes_ids = commandes.pluck(:id)
      ca_paiements = @paiementsFiltres.only_prix.where(commande_id: commandes_ids).sum(:montant).to_d
      ca_stripe = stripe_amount_eur(@stripePaymentsPaidFiltres.where(commande_id: commandes_ids))
      ca = ca_paiements + ca_stripe

      devis_count = commandesDevis.where(profile_id: profile.id).count

      ratio = index.to_f / [total - 1, 1].max

      r = (base_r + (target_r - base_r) * ratio).round
      g = (base_g + (target_g - base_g) * ratio).round
      b = (base_b + (target_b - base_b) * ratio).round

      couleur = "rgb(#{r}, #{g}, #{b})"

      label = profile.full_name.presence || profile.prenom.presence || "Profil ##{profile.id}"

      {
        profile: label,
        commandes: commandes.count,
        devis: devis_count,
        ca: ca,
        couleur: couleur
      }
    end
  end

  private

  def stripe_amount_eur(scope)
    scope.sum(:amount).to_d / 100
  end

  # Fusionne deux groupes DATE(...) => montant (BigDecimal), clés au format jj/mm/aaaa
  def merge_grouped_by_day(hash_a, hash_b)
    merged = Hash.new(0.to_d)
    [hash_a, hash_b].each do |h|
      h.each do |date_key, amount|
        label = I18n.l(Date.parse(date_key.to_s), format: "%d/%m/%Y")
        merged[label] += amount.to_d
      end
    end
    merged.sort_by { |k, _| Date.strptime(k, "%d/%m/%Y") }.to_h
  end
end
