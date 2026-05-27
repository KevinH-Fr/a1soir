# frozen_string_literal: true

module ProductsSeoAi
  module Paths
    module_function

    def root
      Rails.root.join("tmp", "seo_ai")
    end

    def families_json
      root.join("families.json")
    end

    def batches_dir
      root.join("batches")
    end

    def batch_file(index)
      batches_dir.join(format("%04d.json", index))
    end

    def ensure_dirs!
      FileUtils.mkdir_p(batches_dir)
    end
  end
end
