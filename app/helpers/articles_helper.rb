module ArticlesHelper
    def badges_articles_synthese(articles)
      content_tag(:div, class: "container-fluid text-center p-1 mb-3") do
        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
          concat("Articles: ")
          concat(content_tag(:span, articles.count, class: ""))
        end)
  
        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
          concat("Prix: ")
          concat(content_tag(:span, articles.sum(:total), class: ""))
        end)

        concat(content_tag(:span, class: "badge fs-5 bg-secondary mx-1") do
            concat("Caution: ")
            concat(content_tag(:span, articles.sum(:totalcaution), class: ""))
        end)

      end
    end
  end
  