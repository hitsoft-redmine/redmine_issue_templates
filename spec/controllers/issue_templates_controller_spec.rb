# frozen_string_literal: true

require_relative '../spec_helper'
require File.expand_path(File.dirname(__FILE__) + '/../support/controller_helper')

include ControllerHelper
#
# Shared Example
#
shared_examples 'Right response for GET #index', type: :controller do
  include_examples 'Right response', 200
end

describe IssueTemplatesController do
  let(:count) { 4 }
  let(:tracker) { FactoryGirl.create(:tracker, :with_default_status) }
  let(:project) { FactoryGirl.create(:project) }

  include_context 'As admin'
  before do
    Redmine::Plugin.register(:redmine_issue_templates) do
      settings partial: 'settings/redmine_issue_templates',
               default: { 'apply_global_template_to_all_projects' => 'false' }
    end

    Setting.rest_api_enabled = '1'
    @request.session[:user_id] = user.id
    FactoryGirl.create(:enabled_module, project_id: project.id)
    global_issue_templates = FactoryGirl.create_list(:global_issue_template, count, tracker_id: tracker.id)
    global_issue_templates.each { |template| template.projects << project }
    FactoryGirl.create(:issue_template, tracker_id: tracker.id, project_id: project.id)
    project.trackers << tracker
  end

  after(:all) do
    Redmine::Plugin.unregister(:redmine_issue_templates)
  end

  describe 'GET #index' do
    render_views

    before do
      get :index, params: { project_id: project.id }
    end
    include_examples 'Right response for GET #index'
  end

  describe 'GET #index with format.json' do
    render_views
    context 'Without auth header' do
      before do
        clear_token
        get :index, params: { project_id: project.id }, format: :json
      end
      include_examples 'Right response', 401
      after do
        clear_token
      end
    end

    context 'With auth header' do
      before do
        auth_with_user user
        get :index, params: { project_id: project.id }, format: :json
      end
      include_examples 'Right response for GET #index'
      it { expect(response.header['Content-Type']).to match('application/json') }
      it { expect(JSON.parse(response.body)).to have_key('global_issue_templates') }
      after do
        clear_token
      end
    end
  end

  describe 'GET #list_templates' do
    context 'Plugin Setting apply_global_template_to_all_projects is not activated' do
      before do
        get :list_templates, params: { project_id: project.id, issue_tracker_id: tracker.id }
      end

      include_examples 'Right response', 200
    end

    context 'Plugin Setting apply_global_template_to_all_projects is activated' do
      before do
        Setting.send 'plugin_redmine_issue_templates=', 'apply_global_template_to_all_projects' => 'true'
        get :list_templates, params: { project_id: project.id, issue_tracker_id: tracker.id }
      end

      include_examples 'Right response', 200
    end
  end

  describe 'GET #list_templates with format.json' do
    render_views
    context 'Without auth header' do
      before do
        clear_token
        get :list_templates, params: { project_id: project.id,
                                       issue_tracker_id: tracker.id }, format: :json
      end
      include_examples 'Right response', 401
      after do
        clear_token
      end
    end

    context 'With auth header' do
      before do
        auth_with_user user
        get :list_templates, params: { project_id: project.id,
                                       issue_tracker_id: tracker.id }, format: :json
      end
      include_examples 'Right response', 200
      it { expect(response.header['Content-Type']).to match('application/json') }
      it { expect(JSON.parse(response.body)).to have_key('global_issue_templates') }
      after do
        clear_token
      end
    end
  end
end
