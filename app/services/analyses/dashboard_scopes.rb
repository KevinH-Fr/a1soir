# frozen_string_literal: true

# Périmètre Analyses : commandes hors devis (dates commande), articles (dates article),
# paiements et Stripe liés aux commandes filtrées. Devis = scope séparé (KPI).
module Analyses
  class DashboardScopes < ApplicationService
    include Admin::ProduitListingFilters

    def initialize(filter_params)
      @filter_params = filter_params.to_h.symbolize_keys
    end

    def call
      datedebut = parse_datetime(@filter_params[:debut])
      datefin = parse_datetime(@filter_params[:fin])

      commandes = scoped_commandes(datedebut, datefin)
      articles = scoped_articles(datedebut, datefin, commandes)
      articles = apply_locvente_filter(articles)

      produits = apply_produit_listing_filters(Produit.all, @filter_params)
      if product_attribute_filtered?
        articles, commandes = apply_product_dimension(articles, commandes, produits)
      else
        commandes = narrow_commandes_for_locvente(commandes, articles)
      end

      sous_articles = scoped_sous_articles(datedebut, datefin, articles)
      paiements = scoped_paiements(datedebut, datefin, commandes)
      stripe_payments = scoped_stripe_payments(datedebut, datefin, commandes)
      stripe_items = scoped_stripe_payment_items(stripe_payments, produits)

      {
        datedebut: datedebut,
        datefin: datefin,
        commandes_filtres: commandes,
        articles_filtres: articles,
        sous_articles_filtres: sous_articles,
        paiements_filtres: paiements,
        stripe_payments_paid_filtres: stripe_payments,
        stripe_payment_items_filtres: stripe_items,
        product_dimension_filtered: product_dimension_filtered?(@filter_params),
        filtered_produits: produits
      }
    end

    private

    def parse_datetime(value)
      return nil if value.blank?

      DateTime.parse(value.to_s)
    end

    def product_attribute_filtered?
      ADMIN_PRODUIT_FILTER_KEYS.any? { |key| @filter_params[key].present? }
    end

    def scoped_commandes(datedebut, datefin)
      scope = Commande.hors_devis
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      if @filter_params[:filter_profile].present?
        scope = scope.where(profile_id: @filter_params[:filter_profile])
      end
      apply_eshop_filter(scope)
    end

    def scoped_articles(datedebut, datefin, commandes)
      scope = Article.joins(:commande).merge(Commande.hors_devis).where(commande_id: commandes.select(:id))
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      scope
    end

    def apply_eshop_filter(commandes)
      case @filter_params[:filter_eshop].to_s
      when "true"
        commandes.where(eshop: true)
      when "false"
        commandes.where(eshop: [false, nil])
      else
        commandes
      end
    end

    def apply_locvente_filter(articles)
      case @filter_params[:filter_locvente].to_s
      when "location"
        articles.merge(Article.location_only)
      when "vente"
        articles.merge(Article.vente_only)
      else
        articles
      end
    end

    # Sans filtre produit attributaire : aligne les commandes sur loc/vente.
    # Vente : conserve aussi l'e-shop (lignes Stripe, pas d'articles).
    def narrow_commandes_for_locvente(commandes, articles)
      case @filter_params[:filter_locvente].to_s
      when "location"
        commandes.where(id: articles.select(:commande_id))
      when "vente"
        article_commande_ids = articles.distinct.pluck(:commande_id)
        eshop_commande_ids = commandes.where(eshop: true).pluck(:id)
        commandes.where(id: (article_commande_ids + eshop_commande_ids).uniq)
      else
        commandes
      end
    end

    # Inclut les commandes e-shop dont les StripePaymentItems matchent le filtre produit
    # (sinon elles disparaissaient faute d'articles).
    def apply_product_dimension(articles, commandes, produits)
      filtered_articles = articles.joins(:produit).merge(produits)

      article_commande_ids = filtered_articles.distinct.pluck(:commande_id)
      stripe_commande_ids =
        if @filter_params[:filter_locvente].to_s == "location"
          []
        else
          StripePaymentItem.not_refunded
                           .joins(:stripe_payment, :produit)
                           .merge(produits)
                           .where(stripe_payments: { commande_id: commandes.select(:id) })
                           .distinct
                           .pluck("stripe_payments.commande_id")
        end

      commande_ids = (article_commande_ids + stripe_commande_ids).uniq
      [filtered_articles, commandes.where(id: commande_ids)]
    end

    def scoped_sous_articles(datedebut, datefin, articles)
      scope = Sousarticle.joins(article: :commande).merge(Commande.hors_devis)
                           .where(article_id: articles.select(:id))
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      if product_attribute_filtered?
        produits = apply_produit_listing_filters(Produit.all, @filter_params)
        scope = scope.joins(:produit).merge(produits)
      end
      scope
    end

    def scoped_paiements(datedebut, datefin, commandes)
      scope = PaiementRecu.where(commande_id: commandes.select(:id))
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      scope
    end

    def scoped_stripe_payments(datedebut, datefin, commandes)
      scope = StripePayment.paid.where(commande_id: commandes.select(:id))
      if datedebut.present? && datefin.present?
        scope = scope.filtredatedebut(datedebut).filtredatefin(datefin)
      end
      scope
    end

    # Lignes e-shop = toujours vente → exclues si filtre location.
    def scoped_stripe_payment_items(stripe_payments, produits)
      return StripePaymentItem.none if @filter_params[:filter_locvente].to_s == "location"

      scope = StripePaymentItem.not_refunded.where(stripe_payment_id: stripe_payments.select(:id))
      if product_attribute_filtered?
        scope = scope.joins(:produit).merge(produits)
      end
      scope
    end
  end
end
