class AnalysesController < ApplicationController
  before_action :authenticate_vendeur_or_admin!

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
    @groupedByDate = @commandesFiltres.group('DATE(created_at)').count('created_at')

    # articles : 
    @nbTotalArticles = @articlesFiltres.count
    @nbLoc =   @articlesFiltres.location_only.count 
    @nbVente =  @articlesFiltres.vente_only.count 
    @groupedByDateArticles =  @articlesFiltres.group('DATE(articles.created_at)').sum('quantite')

    #  transactions : 
    @totalTransactions = @articlesFiltres.sum(:prix) + @sousArticlesFiltres.sum(:prix)

    @totalTransactionsVente = @articlesFiltres.vente_only.sum(:prix) + @sousArticlesFiltres.vente_only.sum(:prix)
    @totalTransactionsLoc =  @articlesFiltres.location_only.sum(:prix) + @sousArticlesFiltres.location_only.sum(:prix)
    
    @groupedByDateTransactions =  @articlesFiltres.group('DATE(articles.created_at)').sum('total')
    
    # CA 
    @totalCa =  @paiementsFiltres.sum(:montant)
    @totalPrixCa =  @paiementsFiltres.only_prix.sum(:montant)
    @totalCautionCa =  @paiementsFiltres.only_caution.sum(:montant)
    @groupedByDateCa =  @paiementsFiltres.group('DATE(created_at)').sum(:montant)

  end


end
