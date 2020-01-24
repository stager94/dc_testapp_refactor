**Что изменилось и почему**
В целом поменялось практически все. Теперь контроллер отвечает, по-сути, только для того, чтобы принять аргументы и передать их в соответствующие сервисы.

Итак, подробнее начнем с моделей. Тут не так много изменений:
1) Модель Ad: я решил, что потерянную ассоциацию с пользователем необходимо добавить
2) Модель User: тут ничего не поменял
3) Модель PromoMessage: я добавил валидации (я предполагаю, что они необходимы для того, чтобы избежать exception'ов при миссклике по кнопке "сохранить" на форме создания промо сообщения); дальше добавился метод `deliver_messages!`, который вызывает сервис по отправке сообщений пользователям. Почему я не оставил вызов сервиса в контроллере, а вынес его в модель? Представим ситуацию, что мы имеем веб-приложение и мобильное приложение. В таком случае, мы будем иметь 2 разных контроллера для создания промо-сообщения, к примеру. Тогда вызов сервиса будет прописан в 2 местах. Через время сервис может быть изменен (например, переписан на новый сервис или были добавлены доп. аргументы) - тогда нужно будет искать вызов данного сервиса и менять в каждом месте. В данной реализации это будет необходимо сделать только в 1 месте. Однако, можно было бы написать сервис для создания промо сообщения, который примет аргументы и внутри него будут происходить сохранение и отправка сообщений пользователям, но это я опишу чуть позже в секции "мысли и идеи". На текущем этапе, я думаю, что доп. сервис был бы лишним. Но, если бы я видел всю картину приложения, я, возможно, сразу бы создал отдельный сервис для создания промо-сообшения.

Перейдем к контроллеру:
1) `attr_reader :provider` - я не понял к чему здесь лишний ридер, который нигде не используется, поэтому решил избавится от этой строки.
2) В экшине `new` - по непонятным мне причинам при присутствии определенных параметров вызывается метод `get_users`. Имея представление только о контроллере и без информации о вьюшке, я решил, что это будет лишняя нагрузка на выполнение запроса - зачем делать выборку пользователей (а она может быть довольно таки обьемной), если это не будет использоваться? Но я могу ошибаться, так как не видел представление.
3) Экшн `create`. Тут все просто - убираем всю логику из контроллера и выносим по сервисам, а конкретно: мы уже добавили валидации, поэтому при проверке `@promo_message.save` будет либо рендериться страница создания с выводом ошибок, либо мы переходим ко второму шагу - редиректу и отправке сообщений. Из `if` я убрал проверку `send_message(recipients)` - как по мне это бессмысленно, ведь данный метод только добавлял таски в очередь бэкграундным задачам и если на данном этапе будет ошибка, то она бы выдала exception, но не false (допустим, некорректное количество аргументов и т.д.).
4) Приватный метод `get_users` заслуживает отдельного внимания - его я вынес в query object и он используется теперь в сервисе по отправке сообщений. Но, перенес его полностью, а избавился от пейджинации - в любом случае она тут не нужна (либо отправка сообщений будет только N из M пользователям, либо в CSV выгрузится не весь список, а все те же N из M). Так же, были мелкие визуальные правки, на них не буду останавливать свое внимание.
5) Рассмотрим изменения в экшине `download_csv`, а так же в затронутом приватном методе `to_csv`. Тут мы делаем выборку пользователей, используя ранее написанный query object и полученный список пользователей передаем в сервис `UsersCsvReport`, который генерирует CSV файл. Почему я вынес генерацию в отдельный сервис? Я уверен, что в какой то другой части приложения уже есть, либо планируется выгрузка пользователей в CSV и мы сможем смело использовать данный сервис. Но, я бы внес еще туда правки, опишу их в последнем разделе.

Прочие минорные изменения:
В процессе работы я использовал query object, сервисы, микшины. Для первых двух описал базовые классы (уверен, что в существующем приложении таковы уже существуют, но в данном примере их пришлось реализовать). Mixin `Callable` был создан для удобного вызова сервисов - вместо того, чтобы инициализировать в каждом месте новый инстанс, а затем вызывать единственный метод `call`, он помагает сразу вызывать единственный публичный метод (а сервис, по своей природе не может иметь больше одного публичного метода, что подчиняется принципу единичной ответственности).

**С какими проблемами столкнулся в процессе**
Проблем не было. Процесс строился из таких этапов:
1) Ознакомление
2) Выявление лишнего кода
3) Проектирование сервисов
4) Собственно, написание самого кода, создание сервисов, их настройка

**Любые идеи и мысли, чтобы еще сделал при наличии дополнительного времени, и т.д.**

Итак, мои идеи сводятся к тому, что я не имею особого представления о предметной области, а так же о размерах данных. Но, думаю, что имело бы смысл сделать отправку сообщений еще одной джобой. Так как для часто посещяемого и используемого ресурса таких пользователей может быть и миллион и если мы будем отправлять сообщения сразу при вызове метода `create`, то мы можем как получить долгий ответ, так и падение запроса по таймауту. А так же, это нагрузит сервер и понизит пропускную способность. Но, смысл задачи сводился к рефакторингу, а он подразумевает изменение кода без изменения логики, то я не стал делать это в коде прямо сейчас (так как это бы изменило логику - администратор будет ожидать, что сообщения уже отправлены, а они только стоят в очереди).

Так же, мне нравится использовать интеракторы. Из самых крутых фич - это сервис-органайзер, который собирает и выполняет поочередно указанные сервисы, которые делятся между собой контекстом. А сами сервисы-интеракторы имеют возможность отката изменений при возникновении ошибки. В нашем примере можно было бы создать органайзер, который бы вызывал 2 сервиса: первый принимает параметры из контроллера и создает промо-сообщение, а второй занимался бы отправкой самих сообщений. При возникновении ошибок при отправке можно было бы откатить и создание самого промо-сообщения с выводом ошибки пользователю. Так же, данный органайзер и можно было бы использовать в нескольких местах приложения, где есть такая возможность (как и описывал выше - в админ-панели ВЕБ версии и в АПИ для мобильного приложения).

Так же, я думаю что не всегда удобно будет скачивать в формате CSV и в будущем пользователи захотят видеть отчет в XLS/PDF/HTML/Plain text. Реализовать это можно было бы просто создав сервис-стратегию, которая вызывала бы соответствующий сервис для генерации отчета. А вызов сервиса `UsersCsvReport` заменить на вызов нашего сервиса-стратегии с указанием необходимого формата.

Еще, можно было бы расширить сервис `UsersCsvReport`, а именно убрать захардкоженные данные о пользователе, которые выводятся в отчете на аргумент с дефолтным значением. Допустим, какой-то другой отчет может содержать другие столбцы и тогда сервис в текущем виде не подходил бы для выполнения данной задачи.
