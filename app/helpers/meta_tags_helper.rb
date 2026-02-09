module MetaTagsHelper
  META_TAGS = {
    default: {
      title: "Autour D'Un Soir",
      description: "Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les évènementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptèmes. Robes de mariées",
      keywords: "Vente et Location robes de cocktail, Voiles de mariée, Location et vente chaussures vernies, Location et vente pochette de soirée, Vente chemises habillées, Vente et location nœud papillon, cravate, boutons de manchettes, Ceintures habillées, Vente robes de mariée Cannes, Robes de mariées pas chères, Robes de mariées bohème, Robe de mariées princesses, Robes de mariées Sirènes, Chaussures mariées, Accessoires mariés, Costumes de mariés, Costumes témoins, Vente et Location Robes demoiselles d'honneur, Location festival de Cannes, Location robe festival cannes, Location Smoking Festival de Cannes, Location, Fabrication vente de costumes et accessoires, Toutes époques et tous styles, Location de smokings et robes longues, Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les événementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptêmes. Robes de mariées, Smokings, robes longues, tenues de soirées, costumes, Costumes de cérémonies, Queues de pies, Fracs, Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, Location"
    },
    pages: {
      home: {
        title: "Autour D'Un Soir - Robes de mariée et location de bornes photo",
        description: "Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les évènementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptèmes. Robes de mariées",
        keywords: "Vente et Location robes de cocktail, Voiles de mariée, Location et vente chaussures vernies, Location et vente pochette de soirée, Vente chemises habillées, Vente et location nœud papillon, cravate, boutons de manchettes, Ceintures habillées, Vente robes de mariée Cannes, Robes de mariées pas chères, Robes de mariées bohème, Robe de mariées princesses, Robes de mariées Sirènes, Chaussures mariées, Accessoires mariés, Costumes de mariés, Costumes témoins, Vente et Location Robes demoiselles d'honneur, Location festival de Cannes, Location robe festival cannes, Location Smoking Festival de Cannes, Location, Fabrication vente de costumes et accessoires, Toutes époques et tous styles, Location de smokings et robes longues, Des milliers d'articles pour les particuliers, les entreprises, la télé, le cinéma, les événementiels, etc... Location de Costumes Cannes. Tenues de cérémonies, tenues de baptêmes. Robes de mariées, Smokings, robes longues, tenues de soirées, costumes, Costumes de cérémonies, Queues de pies, Fracs, Location, Fabrication et vente de costumes et accessoires. Toutes époques et tous styles. Location de smokings et robes longues. Des milliers d'articles pour les particuliers, Location"
      },
      la_boutique: {
        title: "La boutique - Autour D'Un Soir",
        description: "Visitez notre boutique Autour D'Un Soir. Découvrez nos collections de robes de mariée et nos services.",
        keywords: "boutique mariage, Autour D'Un Soir, Cannes, robes de mariée, essayage"
      },
      nos_collections: {
        title: "Nos collections - Autour D'Un Soir",
        description: "Explorez nos collections de robes de mariée. Large choix de modèles pour votre jour J.",
        keywords: "collections robes de mariée, mariage, Autour D'Un Soir, essayage"
      },
      le_concept: {
        title: "Le concept - Autour D'Un Soir",
        description: "Découvrez l'histoire et les valeurs d'Autour D'Un Soir, votre boutique de robes de mariée à Cannes.",
        keywords: "concept Autour D'Un Soir, histoire, valeurs, boutique mariage"
      },
      cabine_essayage: {
        title: "Cabine d'essayage - Autour D'Un Soir",
        description: "Réservez votre séance d'essayage dans notre cabine privée. Moment personnalisé avec nos conseillères.",
        keywords: "essayage, cabine essayage, rendez-vous, Autour D'Un Soir"
      },
      rdv: {
        title: "Prendre rendez-vous - Autour D'Un Soir",
        description: "Réservez votre rendez-vous en boutique pour découvrir nos collections de robes de mariée.",
        keywords: "rendez-vous, réservation, essayage, Autour D'Un Soir"
      },
      contact: {
        title: "Contact - Autour D'Un Soir",
        description: "Contactez Autour D'Un Soir pour toute question sur nos robes de mariée et nos services de location.",
        keywords: "contact Autour D'Un Soir, adresse, téléphone, email"
      },
      produits: {
        title: "Nos produits - Autour D'Un Soir",
        description: "Découvrez notre catalogue de robes de mariée et accessoires. Large choix de modèles disponibles.",
        keywords: "produits, robes de mariée, catalogue, Autour D'Un Soir"
      },
      nos_autres_activites: {
        title: "Nos autres activités - Autour D'Un Soir",
        description: "Découvrez toutes les activités d'Autour D'Un Soir au-delà des robes de mariée.",
        keywords: "activités Autour D'Un Soir, services, location, vente"
      },
      legal: {
        title: "Mentions légales & Conditions générales - Autour D'Un Soir",
        description: "Consultez les mentions légales, conditions générales de vente et politique de confidentialité d'Autour D'Un Soir.",
        keywords: "CGV, conditions générales de vente, mentions légales, Autour D'Un Soir, location, vente, politique de confidentialité"
      },
      faq: {
        title: "FAQ - Questions fréquemment posées - Autour D'Un Soir",
        description: "Trouvez les réponses aux questions fréquemment posées sur nos services de location et vente de robes de mariée.",
        keywords: "FAQ, questions fréquentes, Autour D'Un Soir, location robes de mariée, vente"
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
    when 'pages#legal'
      :legal
    when 'pages#faq'
      :faq
    when 'pages#produit'
      nil
    else
      nil
    end
  end
end
