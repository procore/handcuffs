require_relative 'spec_helper.rb'

RSpec.describe 'handcuffs:rollback' do
  include_context 'rake'

  let!(:add_table_foo_version) { '20160329040426' } #pre_restart
  let!(:add_column_foo_widget_count_version){ '20160329042840' } #pre_restart
  let!(:add_index_foo_widget_count_version) { '20160329224617' } #post_restart
  let!(:add_column_foo_whatzit_count_version){ '20160330002738' } #pre_restart
  let!(:add_foo_whatzit_default_version){ '20160330003159' } #post_restart
  let!(:add_table_bar_version){ '20160330005509' } #none

  it 'raises an error when not passed a phase argument' do
    expect { subject.invoke }.to raise_error(RequiresPhaseArgumentError)
  end

  it 'raises not configured error if Handcuffs is not configured' do
    Handcuffs.config = nil
    expect { subject.invoke(:pre_restart) }.to raise_error(HandcuffsNotConfiguredError)
  end

  context 'with basic config' do
    before(:all) do
      Handcuffs.configure do |config|
        config.phases = [:pre_restart, :post_restart]
        config.default_phase = :pre_restart
      end
    end

    context '[post_restart]' do

      it 'reverses last post_restart migration' do
        rake['handcuffs:migrate'].invoke(:all)
        subject.invoke(:post_restart)
        expect(SchemaMigrations.pluck(:version)).to eq [
          add_table_foo_version,
          add_column_foo_widget_count_version,
          add_column_foo_whatzit_count_version,
          add_table_bar_version,
          add_index_foo_widget_count_version,
        ]
      end
    end

    context '[pre_restart]' do
      it 'reverses last pre_restart migration' do
        rake['handcuffs:migrate'].invoke(:all)
        subject.invoke(:pre_restart)
        expect(SchemaMigrations.pluck(:version)).to eq [
          add_table_foo_version,
          add_column_foo_widget_count_version,
          add_column_foo_whatzit_count_version,
          add_index_foo_widget_count_version,
          add_foo_whatzit_default_version
        ]
      end

      it 'works with log file' do
        rake['handcuffs:migrate'].invoke(:all)
        filename = 'handcuffs.pre_restart.12343289.json'
        ENV['HANDCUFFS_LOG'] = filename
        begin
          subject.invoke(:pre_restart)
          expect(SchemaMigrations.pluck(:version)).to eq [
            add_table_foo_version,
            add_column_foo_widget_count_version,
            add_column_foo_whatzit_count_version,
            add_index_foo_widget_count_version,
            add_foo_whatzit_default_version
          ]
          hash_array = File.readlines(filename).map { |line| JSON.parse(line).symbolize_keys }
          expect(hash_array.length).to eql 1
          expect(hash_array[0]).to include({
            version: 20160330005509,
            direction: 'down',
            phase: 'pre_restart'
          })
        ensure
          ENV['HANDCUFFS_LOG'] = nil
          File.delete(filename)
        end
      end
    end
  end
end

class SchemaMigrations < ActiveRecord::Base; end