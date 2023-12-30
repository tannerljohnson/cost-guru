class AnomaliesController < ApplicationController
  before_action :authenticate_user!
  before_action :load_account!

  def index
    200
  end
end