if Rails.env.production?
  
    WickedPdf.config ||= {}
    WickedPdf.config.merge!({
      layout: "pdf.html.erb",
    }) 
end