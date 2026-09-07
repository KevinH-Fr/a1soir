class ReplaceDraftIndexesWithDraftStep < ActiveRecord::Migration[7.2]
  IDENTITY = "identity"
  PHOTO = "photo"

  def up
    add_column :mensurations, :draft_step, :string

    Mensuration.reset_column_information
    Mensuration.find_each do |mensuration|
      key = draft_step_from_indexes(mensuration)
      mensuration.update_column(:draft_step, key) if key.present?
    end

    remove_column :mensurations, :draft_wizard_index
    remove_column :mensurations, :draft_guide_index
  end

  def down
    add_column :mensurations, :draft_wizard_index, :integer
    add_column :mensurations, :draft_guide_index, :integer

    remove_column :mensurations, :draft_step
  end

  private

  def draft_step_from_indexes(mensuration)
    wizard_index = mensuration.draft_wizard_index
    guide_index = mensuration.draft_guide_index.to_i
    template = mensuration.template.to_s
    return IDENTITY if wizard_index == 1
    return PHOTO if wizard_index.nil?

    if template == "femme"
      return "mesures.hauteur" if wizard_index == 2 && guide_index <= 0
      return "mesures.vetements" if wizard_index == 2 && guide_index >= 1
      return PHOTO if wizard_index.to_i >= 3

      return IDENTITY
    end

    if template == "homme"
      return "tailles" if wizard_index.to_i <= 2
      return homme_corps_key(mensuration, guide_index) if wizard_index == 3
      return PHOTO if wizard_index.to_i >= 4

      return IDENTITY
    end

    IDENTITY
  end

  def homme_corps_key(mensuration, guide_index)
    clip_fields = Mensuration.fields_for("homme").select { |f| f["step"] == "corps" && f["clip"].present? }
    field = clip_fields[guide_index] || clip_fields.first
    field ? "corps.#{field["key"]}" : PHOTO
  end
end
