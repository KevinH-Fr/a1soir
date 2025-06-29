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
    else
      @commandesFiltres = Commande.hors_devis.all 
      @articlesFiltres = Article.joins(:commande).merge(Commande.hors_devis).all
      @sousArticlesFiltres = Sousarticle.all
      @paiementsFiltres = PaiementRecu.all
    end

    # commandes :
    @nbTotal = @commandesFiltres.count
    @nbRetire = @commandesFiltres.retire.count 
    @nbNonRetire = @commandesFiltres.non_retire.count 
    @nbRendu = @commandesFiltres.rendu.count 

    groupedByDate = @commandesFiltres.group('DATE(created_at)').order('DATE(commandes.created_at)').count('created_at')
    @groupedByDate = groupedByDate.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: '%d/%m/%Y')
    end

    # articles : 
    @nbTotalArticles = @articlesFiltres.count
    @nbLoc =   @articlesFiltres.location_only.count 
    @nbVente =  @articlesFiltres.vente_only.count 

    groupedByDateArticles =  @articlesFiltres.group('DATE(articles.created_at)').order('DATE(articles.created_at)').sum('quantite')
    @groupedByDateArticles = groupedByDateArticles.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: '%d/%m/%Y')
    end
    #  transactions : 
    @totalTransactions = @articlesFiltres.sum(:prix) + @sousArticlesFiltres.sum(:prix)

    @totalTransactionsVente = @articlesFiltres.vente_only.sum(:prix) + @sousArticlesFiltres.vente_only.sum(:prix)
    @totalTransactionsLoc =  @articlesFiltres.location_only.sum(:prix) + @sousArticlesFiltres.location_only.sum(:prix)
    
    groupedByDateTransactions =  @articlesFiltres.group('DATE(articles.created_at)').order('DATE(articles.created_at)').sum('total')
    @groupedByDateTransactions = groupedByDateTransactions.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: '%d/%m/%Y')
    end

    # CA 
    @totalCa =  @paiementsFiltres.sum(:montant)
    
    @totalPrixCa =  @paiementsFiltres.only_prix.sum(:montant)
    @totalPrixCaCb =  @paiementsFiltres.only_prix.only_cb.sum(:montant)
    @totalPrixCaEspeces =  @paiementsFiltres.only_prix.only_espece.sum(:montant)
    @totalPrixCaCheque =  @paiementsFiltres.only_prix.only_cheque.sum(:montant)
    @totalPrixCaVirement =  @paiementsFiltres.only_prix.only_virement.sum(:montant)

    #@totalCautionCa =  @paiementsFiltres.only_caution.sum(:montant)
    groupedByDateCa =  @paiementsFiltres.group('DATE(created_at)').order('DATE(paiement_recus.created_at)').sum(:montant)
    @groupedByDateCa = groupedByDateCa.transform_keys do |date|
      I18n.l(Date.parse(date.to_s), format: '%d/%m/%Y')
    end

    #profiles
    base_r, base_g, base_b = 208, 77, 123
    target_r, target_g, target_b = 245, 190, 210  # limite claire contrôlée

    profiles = Profile.includes(commandes: [:paiement_recus, :articles])
    total = profiles.size
      
    @stats_par_profile = profiles.map.with_index do |profile, index|
      commandes = @commandesFiltres.where(profile_id: profile.id)
      commandes_ids = commandes.pluck(:id)
      paiements = @paiementsFiltres.where(commande_id: commandes_ids)
      ca = paiements.sum(:montant)
  
     devis_count = commandes.est_devis.size

      groupedByDateAndByProfileCa = paiements.group('DATE(created_at)').order('DATE(paiement_recus.created_at)').sum(:montant)

      groupedByDateAndByProfileCaFr = groupedByDateAndByProfileCa.transform_keys do |date|
        I18n.l(Date.parse(date.to_s), format: '%d/%m/%Y')
      end


      ratio = index.to_f / [total - 1, 1].max

      r = (base_r + (target_r - base_r) * ratio).round
      g = (base_g + (target_g - base_g) * ratio).round
      b = (base_b + (target_b - base_b) * ratio).round

      couleur = "rgb(#{r}, #{g}, #{b})"

      {
        profile: profile.prenom, # ou .nom
        commandes: commandes.size,
        devis: devis_count,
        ca: ca,
        ca_par_date: groupedByDateAndByProfileCaFr,
        couleur: couleur
      }
    end

  end


end
