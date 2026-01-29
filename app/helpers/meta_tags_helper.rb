module MetaTagsHelper
  META_TAGS = {
    default: {
      title: "Autour d'un Soir",
      description: "Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les évènementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptèmes. Robes de mariées",
      keywords: "Vente et Location robes de cocktail, Voiles de mariée, Location et vente chaussures vernies, Location et vente pochette de soirée, Vente chemises habillées, Vente et location nœud papillon, cravate, boutons de manchettes, Ceintures habillées, Vente robes de mariée Cannes, Robes de mariées pas chères, Robes de mariées bohème, Robe de mariées princesses, Robes de mariées Sirènes, Chaussures mariées, Accessoires mariés, Costumes de mariés, Costumes témoins, Vente et Location Robes demoiselles d'honneur, Location festival de Cannes, Location robe festival cannes, Location Smoking Festival de Cannes, Location, Fabrication vente de costumes et accessoires, Toutes époques et tous styles, Location de smokings et robes longues, Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les événementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptêmes. Robes de mariées, Smokings, robes longues, tenues de soirées, costumes, Costumes de cérémonies, Queues de pies, Fracs, Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, Location"
    },
    pages: {
      home: {
        title: "Autour d'un Soir - Robes de mariée et location de bornes photo",
        description: "Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les évènementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptèmes. Robes de mariées",
        keywords: "Vente et Location robes de cocktail, Voiles de mariée, Location et vente chaussures vernies, Location et vente pochette de soirée, Vente chemises habillées, Vente et location nœud papillon, cravate, boutons de manchettes, Ceintures habillées, Vente robes de mariée Cannes, Robes de mariées pas chères, Robes de mariées bohème, Robe de mariées princesses, Robes de mariées Sirènes, Chaussures mariées, Accessoires mariés, Costumes de mariés, Costumes témoins, Vente et Location Robes demoiselles d'honneur, Location festival de Cannes, Location robe festival cannes, Location Smoking Festival de Cannes, Location, Fabrication vente de costumes et accessoires, Toutes époques et tous styles, Location de smokings et robes longues, Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les événementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptêmes. Robes de mariées, Smokings, robes longues, tenues de soirées, costumes, Costumes de cérémonies, Queues de pies, Fracs, Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, Location"
      },
      la_boutique: {
        title: "La boutique - Autour d'un Soir",
        description: "Visitez notre boutique Autour d'un Soir. Découvrez nos collections de robes de mariée et nos services.",
        keywords: "boutique mariage, Autour d'un Soir, Cannes, robes de mariée, essayage"
      },
      nos_collections: {
        title: "Nos collections - Autour d'un Soir",
        description: "Explorez nos collections de robes de mariée. Large choix de modèles pour votre jour J.",
        keywords: "collections robes de mariée, mariage, Autour d'un Soir, essayage"
      },
      le_concept: {
        title: "Le concept - Autour d'un Soir",
        description: "Découvrez l'histoire et les valeurs d'Autour d'un Soir, votre boutique de robes de mariée à Cannes.",
        keywords: "concept Autour d'un Soir, histoire, valeurs, boutique mariage"
      },
      cabine_essayage: {
        title: "Cabine d'essayage - Autour d'un Soir",
        description: "Réservez votre séance d'essayage dans notre cabine privée. Moment personnalisé avec nos conseillères.",
        keywords: "essayage, cabine essayage, rendez-vous, Autour d'un Soir"
      },
      rdv: {
        title: "Prendre rendez-vous - Autour d'un Soir",
        description: "Réservez votre rendez-vous en boutique pour découvrir nos collections de robes de mariée.",
        keywords: "rendez-vous, réservation, essayage, Autour d'un Soir"
      },
      contact: {
        title: "Contact - Autour d'un Soir",
        description: "Contactez Autour d'un Soir pour toute question sur nos robes de mariée et nos services de location.",
        keywords: "contact Autour d'un Soir, adresse, téléphone, email"
      },
      produits: {
        title: "Nos produits - Autour d'un Soir",
        description: "Découvrez notre catalogue de robes de mariée et accessoires. Large choix de modèles disponibles.",
        keywords: "produits, robes de mariée, catalogue, Autour d'un Soir"
      },
      nos_autres_activites: {
        title: "Nos autres activités - Autour d'un Soir",
        description: "Découvrez toutes les activités d'Autour d'un Soir au-delà des robes de mariée.",
        keywords: "activités Autour d'un Soir, services, location, vente"
      },
      cgv: {
        title: "Conditions générales de vente - Autour d'un Soir",
        description: "Consultez les conditions générales de vente d'Autour d'un Soir pour la location et la vente de robes de mariée.",
        keywords: "CGV, conditions générales de vente, Autour d'un Soir, location, vente"
      },
      faq: {
        title: "FAQ - Questions fréquemment posées - Autour d'un Soir",
        description: "Trouvez les réponses aux questions fréquemment posées sur nos services de location et vente de robes de mariée.",
        keywords: "FAQ, questions fréquentes, Autour d'un Soir, location robes de mariée, vente"
      }
    }
  }.freeze

  def meta_title(page_key = nil)
    content_for?(:title) ? content_for(:title) : meta_tag_value(:title, page_key)
  end

  def meta_description(page_key = nil)
    meta_tag_value(:description, page_key)
  end

  def meta_keywords(page_key = nil)
    meta_tag_value(:keywords, page_key)
  end

  private

  def meta_tag_value(key, page_key = nil)
    # Si content_for est défini, il a la priorité
    content_for_key = "meta_#{key}".to_sym
    return content_for(content_for_key) if content_for?(content_for_key)

    # Déterminer la clé de page à utiliser
    page_key ||= determine_page_key

    # Récupérer les meta tags pour la page spécifique ou les valeurs par défaut
    page_meta = (page_key && META_TAGS[:pages][page_key.to_sym]) || META_TAGS[:default]

    page_meta[key] || META_TAGS[:default][key]
  end

  def determine_page_key
    controller_name = controller.controller_name
    action_name = controller.action_name

    case "#{controller_name}##{action_name}"
    when 'pages#home'
      :home
    when 'pages#la_boutique'
      :la_boutique
    when 'pages#nos_collections'
      :nos_collections
    when 'pages#le_concept'
      :le_concept
    when 'pages#cabine_essayage'
      :cabine_essayage
    when 'pages#rdv'
      :rdv
    when 'pages#contact'
      :contact
    when 'pages#produits'
      :produits
    when 'pages#nos_autres_activites'
      :nos_autres_activites
    when 'pages#cgv'
      :cgv
    when 'pages#faq'
      :faq
    when 'pages#produit'
      nil
    else
      nil
    end
  end
end
