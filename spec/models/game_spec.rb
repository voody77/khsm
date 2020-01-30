# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  context 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
          change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
              change(Question, :count).by(0) # Game.count не должен измениться
          )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq (0..14).to_a
    end
  end


  # тесты на основную игровую логику
  context 'game mechanics' do

    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it '.take_money!' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.to_a.sample
      game_w_questions.take_money!

      #проверка что выйгрышь соответствует своему уровню
      expect(game_w_questions.prize).to eq Game::PRIZES[game_w_questions.current_level - 1]
      #проверка, что игроку выйгрышь пришёл на баланс
      expect(user.balance).to eq game_w_questions.prize
      # --//-- что игра окончена
      expect(game_w_questions.finished?).to be_truthy
    end

    it '.current_game_question' do
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[0])
    end

    describe '#previous_level' do
      context 'in the beginning of the game' do
        it 'returns right value' do
          expect(game_w_questions.previous_level).to eq(-1)
        end
      end

      context 'during the game' do
        it 'returns right value for each level' do
          Question::QUESTION_LEVELS.max.times do
            q_cak = game_w_questions.current_game_question.correct_answer_key
            game_w_questions.answer_current_question!(q_cak)
            expect(game_w_questions.previous_level).to eq(game_w_questions.current_level - 1)
          end
        end
      end

      context 'in the end of the game' do
        it 'returns right value in the end' do
          game_w_questions.current_level = Question::QUESTION_LEVELS.max
          q_cak = game_w_questions.current_game_question.correct_answer_key
          game_w_questions.answer_current_question!(q_cak)
          expect(game_w_questions.previous_level).to eq(Question::QUESTION_LEVELS.max)
        end
      end
    end

    context 'correct .status' do
      before(:each) do
        game_w_questions.finished_at = Time.current
      end

      it ':won' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
        expect(game_w_questions.status).to eq(:won)
      end

      it ':money' do
        expect(game_w_questions.status).to eq(:money)
      end

      it ':fail' do
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:fail)
      end

      it ':timeout' do
        game_w_questions.created_at = 40.minutes.ago
        game_w_questions.is_failed = true
        expect(game_w_questions.status).to eq(:timeout)
      end
    end

    context '.answer_current_question!' do
      let!(:q_cak) { game_w_questions.current_game_question.correct_answer_key }

      it 'be_truthy' do
        expect(game_w_questions.answer_current_question!(q_cak)).to be_truthy
      end

      it 'increase current_level' do
        expect { game_w_questions.answer_current_question!(q_cak) }.to change(game_w_questions, :current_level).by(1)
      end

      it 'finished game after last question' do
        game_w_questions.current_level = Question::QUESTION_LEVELS.max
        expect { game_w_questions.answer_current_question!(q_cak) }.to change(game_w_questions, :status)
                                                                           .from(:in_progress).to(:won)
      end
    end
  end
end
