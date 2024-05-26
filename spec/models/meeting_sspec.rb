require 'rails_helper'

RSpec.describe 'Meeting' do           


  describe '#start_time' do
    it 'returns the start time (datedebut)' do
      expect(Meeting.start_time).to eq(DateTime.new(2024, 5, 26, 14, 30))
    end
  end

  describe '#end_time' do
    it 'returns the end time (datefin)' do
      expect(Meeting.end_time).to eq(DateTime.new(2024, 5, 26, 15, 30))
    end
  end

  describe '#meeting_info' do
    it 'returns the formatted meeting info' do
      expect(Meeting.meeting_info).to eq('26-05 14:30 - Test Name - Client Full Name')
    end
  end
end
