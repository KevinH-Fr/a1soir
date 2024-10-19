WickedPdf.config = {
    # Path to the wkhtmltopdf executable: This usually isn't needed if using
    # one of the wkhtmltopdf-binary family of gems.
    # exe_path: '/usr/local/bin/wkhtmltopdf',
    #   or
    # exe_path: Gem.bin_path('wkhtmltopdf-binary', 'wkhtmltopdf')
  
    # Needed for wkhtmltopdf 0.12.6+ to use many wicked_pdf asset helpers
    # enable_local_file_access: true,
  
    # Layout file to be used for all PDFs
    # (but can be overridden in `render :pdf` calls)
    # layout: 'pdf.html',
  
    # Using wkhtmltopdf without an X server can be achieved by enabling the
    # 'use_xvfb' flag. This will wrap all wkhtmltopdf commands around the
    # 'xvfb-run' command, in order to simulate an X server.
    #
    # use_xvfb: true,

    
  }