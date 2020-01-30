require 'rails_helper'

RSpec.feature 'USER View someone else’s profile', type: :feature do
  let(:user) { FactoryBot.create :user, name: 'Jack' }
  let(:user2) { FactoryBot.create :user, name: 'Boby' }

  let!(:games) do
    [
      FactoryBot.create(:game, id: 15, user: user2, current_level: 10, prize: 1000, finished_at: Time.current),
      FactoryBot.create(:game, id: 16, user: user2, current_level: 11, prize: 10000, finished_at: Time.current, is_failed: true),
      FactoryBot.create(:game, id: 17, user: user2, current_level: 12, prize: 20000)
    ]
  end

  before(:each) { login_as user }

  scenario 'successfully' do
    visit '/'

    click_link 'Boby'

    expect(page).to have_current_path '/users/1'
    expect(page).to have_link 'Jack - 0 ₽'
    expect(page).to have_content 'Boby'
    expect(page).not_to have_content 'Сменить имя и пароль'

    expect(page).to have_content '15'
    expect(page).to have_content 'деньги'
    expect(page).to have_content '10'
    expect(page).to have_content '1 000 ₽'

    expect(page).to have_content '16'
    expect(page).to have_content 'проигрыш'
    expect(page).to have_content '11'
    expect(page).to have_content '10 000 ₽'

    expect(page).to have_content '17'
    expect(page).to have_content 'в процессе'
    expect(page).to have_content '12'
    expect(page).to have_content '20 000 ₽'
  end
end
