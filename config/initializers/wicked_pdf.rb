if Rails.env.production?
  
  # fonctionne en prod : 
    WickedPdf.config ||= {}
    WickedPdf.config.merge!({
      layout: "pdf.html.erb",
    }) 
end