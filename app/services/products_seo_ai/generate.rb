# frozen_string_literal: true

require "json"

module ProductsSeoAi
  class Generate
    def self.call(batch_size: nil, batch_from: nil, force: false, limit: nil)
      new(
        batch_size: batch_size,
        batch_from: batch_from,
        force: force,
        limit: limit
      ).call
    end

    def initialize(batch_size: nil, batch_from: nil, force: false, limit: nil)
      @batch_size = (batch_size || ENV.fetch("BATCH_SIZE", Config.default_batch_size.to_s)).to_i
      @batch_from = (batch_from || ENV.fetch("BATCH_FROM", "1")).to_i
      @force = force || ENV["FORCE"] == "true"
      @sleep_seconds = ENV.fetch("SEO_AI_SLEEP", "2").to_f
      @max_retries = ENV.fetch("SEO_AI_MAX_RETRIES", "3").to_i
      @limit = (limit || ENV["LIMIT"])&.to_i
    end

    def call
      abort "Fichier familles introuvable. Lancez products:seo_ai_prepare d'abord." unless Paths.families_json.exist?

      data = JSON.parse(File.read(Paths.families_json))
      families = data["families"] || []
      families = families.first(@limit) if @limit&.positive?

      puts "Limite active : #{@limit} familles" if @limit&.positive?

      batches = families.each_slice(@batch_size).to_a

      Paths.ensure_dirs!

      puts "Familles : #{families.size}"
      puts "Batches  : #{batches.size} (taille #{@batch_size})"
      puts "Depuis   : batch #{@batch_from}"
      puts

      batches.each_with_index do |batch_families, index|
        batch_number = index + 1
        next if batch_number < @batch_from

        path = Paths.batch_file(batch_number)

        if path.exist? && !@force
          puts "[SKIP] Batch #{batch_number}/#{batches.size} déjà présent : #{path}"
          next
        end

        puts "[RUN] Batch #{batch_number}/#{batches.size} (#{batch_families.size} familles)..."

        items = call_with_retries(batch_families)

        payload = {
          "batch_index" => batch_number,
          "generated_at" => Time.current.iso8601,
          "model" => ENV.fetch("SEO_AI_MODEL", OpenaiBatchClient::DEFAULT_MODEL),
          "handles" => batch_families.map { |f| f["handle"] },
          "items" => normalize_items(items, batch_families)
        }

        File.write(path, JSON.pretty_generate(payload))
        puts "       → #{path}"

        sleep(@sleep_seconds) if batch_number < batches.size && @sleep_seconds.positive?
      end

      completed = Dir.glob(Paths.batches_dir.join("*.json")).size
      puts
      puts "Terminé. #{completed}/#{batches.size} fichiers batch."
    end

    private

    def call_with_retries(batch_families)
      attempt = 0

      begin
        attempt += 1
        OpenaiBatchClient.call(families: batch_families)
      rescue StandardError => e
        raise e if attempt >= @max_retries

        wait = 2**attempt
        puts "       [RETRY #{attempt}/#{@max_retries}] #{e.class}: #{e.message} — pause #{wait}s"
        sleep(wait)
        retry
      end
    end

    def normalize_items(items, batch_families)
      by_handle = batch_families.index_by { |f| f["handle"] }
      expected_handles = by_handle.keys

      normalized = items.map do |item|
        handle = item["handle"].to_s.strip
        {
          "handle" => handle,
          "new_nom" => item["new_nom"].to_s.strip,
          "approved" => !!item["approved"],
          "notes" => item["notes"].to_s.strip
        }
      end

      returned_handles = normalized.map { |i| i["handle"] }
      missing = expected_handles - returned_handles
      extra = returned_handles - expected_handles

      puts "       [WARN] Handles manquants : #{missing.join(', ')}" if missing.any?
      puts "       [WARN] Handles inattendus : #{extra.join(', ')}" if extra.any?

      normalized
    end
  end
end
