class NotesController < ApplicationController
  respond_to :html, :json

  def index
    @notes = Note.all
    respond_with @notes
  end
end
