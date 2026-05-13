class HomeController < ApplicationController
  def show
    redirect_to boards_path
  end
end
