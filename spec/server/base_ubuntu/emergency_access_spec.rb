require_relative './../spec_helper'


describe 'Emergency ASF Access' do
  describe user('asf999') do
    it { should exist }
  end
end
