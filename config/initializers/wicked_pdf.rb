WickedPdf.config = {
    # En développement, on force le binaire système (/usr/bin/wkhtmltopdf installé via apt)
    # pour éviter que rbenv intercepte l'appel via ses shims et utilise le binaire du gem
    # qui ne fonctionne pas sous WSL.
    # En production (Heroku), exe_path est nil → wkhtmltopdf-heroku fournit son propre binaire.
    exe_path: Rails.env.development? ? '/usr/bin/wkhtmltopdf' : nil
  }.compact