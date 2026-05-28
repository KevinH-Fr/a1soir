module EtiquettesHelper
  # Grille 2×2 — hauteur calibrée wkhtmltopdf (défaut 1420 px ; ENV ETIQUETTE_PDF_PAGE_HEIGHT_PX).
  ETIQUETTE_PDF_PAGE_HEIGHT_PX_DEFAULT = 1415
  # Marge par <tr> de la grille (bordures + arrondis wkhtmltopdf).
  ETIQUETTE_PDF_ROW_SLACK_PX = 6
  # Espace image → bloc QR + textes (padding bas de l’image).
  ETIQUETTE_BODY_GAP_PX = 4
  # Marge interne basse du bloc corps (wkhtmltopdf / lignes prix).
  ETIQUETTE_BODY_SLACK_PX = 4
  ETIQUETTE_TITRE_PRIX_GAP_PX = 8
  ETIQUETTE_META_LINES = 2
  # Hauteur par ligne (badges 11 pt + bordures) — sync avec .etiquette-meta line-height en CSS.
  ETIQUETTE_META_LINE_PX = 24
  ETIQUETTE_META_SECTION_GAP_PX = 4
  ETIQUETTE_META_PAD_X_PX = 8
  # Marge autour du bloc tailles/couleurs (ajuster top/bottom indépendamment si besoin).
  ETIQUETTE_META_PAD_TOP_PX = 3
  ETIQUETTE_META_PAD_BOTTOM_PX = 2
  # Padding interne des badges — ENV top/bottom ; x fixe dans etiquettes_pdf.css.
  ETIQUETTE_BADGE_PAD_TOP_PX_DEFAULT = 2
  ETIQUETTE_BADGE_PAD_BOTTOM_PX_DEFAULT = 0
  ETIQUETTE_BADGE_PAD_X_PX = 3
  ETIQUETTE_IMAGE_PAD_TOP_PX = 8
  ETIQUETTE_IMAGE_PAD_X_PX = 8
  ETIQUETTE_QR_PX = 120
  ETIQUETTE_VERSO_LINES = 12
  ETIQUETTE_VERSO_PAD_X_PX = 10
  ETIQUETTE_VERSO_PAD_Y_PX = 10

  def etiquettes_pdf
    page_h = ENV.fetch("ETIQUETTE_PDF_PAGE_HEIGHT_PX", ETIQUETTE_PDF_PAGE_HEIGHT_PX_DEFAULT).to_i
    row_h = page_h / 2
    grid_row_h = row_h - ETIQUETTE_PDF_ROW_SLACK_PX

    { page_h: page_h, row_h: row_h, grid_row_h: grid_row_h, grid_h: grid_row_h * 2 }
  end

  # Cellule étiquette : image + QR/nom/prix + tailles/couleurs — somme = row_h.
  def etiquettes_cell_layout(pdf)
    cell_h = pdf[:grid_row_h]
    body_h = ETIQUETTE_QR_PX + ETIQUETTE_BODY_SLACK_PX
    meta_block_h = ETIQUETTE_META_LINES * ETIQUETTE_META_LINE_PX
    meta_h = (2 * meta_block_h) + ETIQUETTE_META_SECTION_GAP_PX + ETIQUETTE_META_PAD_TOP_PX + ETIQUETTE_META_PAD_BOTTOM_PX
    img_h = [cell_h - body_h - meta_h, 1].max
    {
      cell_h: cell_h,
      img_h: img_h,
      body_h: body_h,
      body_inner_h: body_h,
      body_gap: ETIQUETTE_BODY_GAP_PX,
      meta_h: meta_h,
      meta_block_h: meta_block_h,
      meta_line_h: ETIQUETTE_META_LINE_PX,
      meta_pad_x: ETIQUETTE_META_PAD_X_PX,
      meta_pad_top: ETIQUETTE_META_PAD_TOP_PX,
      meta_pad_bottom: ETIQUETTE_META_PAD_BOTTOM_PX,
      meta_section_gap: ETIQUETTE_META_SECTION_GAP_PX,
      image_pad_top: ETIQUETTE_IMAGE_PAD_TOP_PX,
      image_pad_x: ETIQUETTE_IMAGE_PAD_X_PX,
      image_pad_bottom: ETIQUETTE_BODY_GAP_PX,
      image_bg_h: [
        img_h - ETIQUETTE_IMAGE_PAD_TOP_PX - ETIQUETTE_BODY_GAP_PX,
        1
      ].max,
      qr_w: ETIQUETTE_QR_PX,
      titre_prix_gap: ETIQUETTE_TITRE_PRIX_GAP_PX
    }
  end

  def etiquettes_verso_layout(grid_row_h)
    pad_x = ETIQUETTE_VERSO_PAD_X_PX
    pad_y = ETIQUETTE_VERSO_PAD_Y_PX
    inner_h = grid_row_h - (2 * pad_y)
    slot_h = inner_h / ETIQUETTE_VERSO_LINES
    { inner_h: inner_h, slot_h: slot_h, lines: ETIQUETTE_VERSO_LINES, pad_x: pad_x, pad_y: pad_y }
  end

  def etiquettes_badge_pad_top
    ENV.fetch("ETIQUETTE_BADGE_PAD_TOP_PX", ETIQUETTE_BADGE_PAD_TOP_PX_DEFAULT).to_i
  end

  def etiquettes_badge_pad_bottom
    ENV.fetch("ETIQUETTE_BADGE_PAD_BOTTOM_PX", ETIQUETTE_BADGE_PAD_BOTTOM_PX_DEFAULT).to_i
  end

  def pad_etiquette_slots(produits, size = 4)
    (produits.first(size) + Array.new(size, nil)).take(size)
  end

  def etiquette_produit_image_url(produit, width: 600, height: nil)
    if produit.image1.attached?
      key = produit.image1.blob.key
      transforms = ["q_auto", "f_auto", "w_#{width}"]
      transforms += ["h_#{height}", "c_limit"] if height.present?
      "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/#{transforms.join(',')}/#{key}"
    else
      no_photo_url
    end
  end

  def etiquette_cell_background_style(produit, pdf, width: 380, height: nil, inset_px: 8)
    return "" unless produit

    img_h = height || (pdf[:row_h] - inset_px)
    url = etiquette_produit_image_url(produit, width: width, height: img_h)
    safe_url = url.to_s.gsub("'", "%27")
    "background-image:url('#{safe_url}');background-repeat:no-repeat;background-position:center center;background-size:contain;background-origin:content-box;background-clip:content-box;"
  end

  def etiquette_qr_background_style(produit)
    url = etiquette_qr_image_url(produit)
    return "" unless url

    safe_url = url.to_s.gsub("'", "%27")
    "background-image:url('#{safe_url}');background-repeat:no-repeat;background-position:center center;background-size:contain;"
  end

  # Fichier source 120×120 px, sans transformation Cloudinary.
  def etiquette_qr_image_url(produit)
    return unless produit.qr_code.attached?

    key = produit.qr_code.blob.key
    "#{ApplicationHelper::CLOUDINARY_BASE_IMAGE_URL}/#{key}"
  end
end
