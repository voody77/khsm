require 'rails_helper'

RSpec.describe 'users/show', type: :view do
  let!(:user) { FactoryBot.build_stubbed(:user, name: 'Вадик', balance: 5000) }
  let!(:games) { FactoryBot.build_stubbed(:game, id: 15, created_at: Time.current, current_level: 10, prize: 1000) }

  before(:each) do
    assign(:user, user)
    assign(:games, [games])

    render
  end

  context 'when user anon' do
    it 'renders player name' do
      expect(rendered).to match 'Вадик'
    end

    it 'does nott render change password button' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders fragments with the game' do
      assert_template partial: 'users/_game'
    end
  end

  context 'when user login' do
    let!(:user) { FactoryBot.create(:user) }

    before(:each) do
      sign_in user

      render
    end

    it 'renders player name' do
      expect(rendered).to match /Жора_*/
    end

    it 'render change password button' do
      expect(rendered).to match 'Сменить имя и пароль'
    end

    it 'renders fragments with the game' do
      assert_template partial: 'users/_game'
    end
  end
end