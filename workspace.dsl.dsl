workspace "Fitness Tracker" "Домашняя работа 01. Документирование архитектуры в Structurizr - Вариант 14" {

    model {
        user = person "Пользователь" "Использует фитнес-трекер для ведения дневника тренировок, отслеживает прогресс, получает статистику"

        emailSystem = softwareSystem "Email Service" "Внешний сервис электронной почты для отправки email-уведомлений. Необходим для подстверждения регистрации, восстановления пароля."
        pushSystem = softwareSystem "Push Notification Service" "Внешний сервис push-уведомлений. Напоминает о тренировках."

        fitnessSystem = softwareSystem "Fitness Tracker System" "Платформа для ведения учета тренировок, упражнений и анализа прогресса." {

            mobileApp = container "Mobile App" "Клиентское приложение для iOS/Android." "React Native"
            apiGateway = container "API Gateway" "Единая точка входа, маршрутизация и аутентификация." "Kong"

            userService = container "User Service" "Управление действиями пользователей (регистрация, поиск и тд)." "Go (gRPC)"
            exerciseService = container "Exercise Service" "Каталог упражнений." "Go (gRPC)"
            workoutService = container "Workout Service" "Создание и управление тренировками." "Go (gRPC)"
            statisticsService = container "Statistics Service" "Агрегация статистики тренировок за период." "Python (FastAPI)"

            cache = container "Cache" "Кэширование часто запрашиваемых данных." "Redis"
            messageBroker = container "Message Broker" "Асинхронная доставка событий." "Apache Kafka"
            database = container "Database" "Хранит данные пользователей, упражнений и тд" "PostgreSQL"
            notificationConsumer = container "Notification Consumer" "Обрабатывает события и отправляет уведомления через внешние сервисы." "Node.js"
        }

        user -> mobileApp "Работает с системой" "HTTPS"

        mobileApp -> apiGateway "Вызывает API" "HTTPS/REST"

        apiGateway -> userService "Запросы пользователей" "gRPC"
        apiGateway -> exerciseService "Запросы упражнений" "gRPC"
        apiGateway -> workoutService "Запросы тренировок" "gRPC"
        apiGateway -> statisticsService "Запросы статистики" "gRPC"

        workoutService -> exerciseService "Проверка существования упражнения" "gRPC"

        userService -> database "Чтение/запись пользователей" "JDBC"
        exerciseService -> database "Чтение/запись упражнений" "JDBC"
        workoutService -> database "Чтение/запись тренировок" "JDBC"
        statisticsService -> database "Агрегирующие запросы" "JDBC"

        userService -> cache "Кэширование пользователей" "Redis protocol"
        exerciseService -> cache "Кэширование упражнений" "Redis protocol"
        workoutService -> cache "Кэширование тренировок" "Redis protocol"
        statisticsService -> cache "Кэширование статистики" "Redis protocol"

        userService -> messageBroker "Публикация UserRegistered" "Kafka API"
        workoutService -> messageBroker "Публикация WorkoutUpdated" "Kafka API"
        statisticsService -> messageBroker "Публикация StatisticsCalculated" "Kafka API"

        notificationConsumer -> messageBroker "Подписка на события" "Kafka API"
        notificationConsumer -> emailSystem "Отправка email" "HTTPS"
        notificationConsumer -> pushSystem "Отправка push" "HTTPS"
    }

    views {
        systemContext fitnessSystem "SystemContext" {
            include user
            include fitnessSystem
            include emailSystem
            include pushSystem
            autolayout lr
        }

        container fitnessSystem "Containers" {
            include user
            include *
            autolayout lr
        }

        dynamic fitnessSystem "GetStatistics" {
title "Получение статистики тренировок за период"
            autolayout lr

            user -> mobileApp "1. Запрашивает статистику"
            mobileApp -> apiGateway "2. GET /statistics?period=..."
            apiGateway -> statisticsService "3. GetStatistics gRPC"
            statisticsService -> cache "4. Проверка кэша"
            cache -> statisticsService "5. Miss"
            statisticsService -> database "6. Агрегация данных за период"
            database -> statisticsService "7. Результат"
            statisticsService -> cache "8. Сохранение в кэш"
            statisticsService -> apiGateway "9. Возврат данных"
            apiGateway -> mobileApp "10. Ответ"
            statisticsService -> messageBroker "11. Публикация StatisticsCalculated"
            notificationConsumer -> messageBroker "12. Чтение события"
            notificationConsumer -> pushSystem "13. Отправка push-уведомления"
        }
