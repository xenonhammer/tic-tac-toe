# tic-tac-toe

Основные методы:

Учавствуют три основных виджета:
    1.buildMessage(),
        Выводит текст на экран;


    2.buildInputName(),
        Поле ввода имени игрока.

    3.buildGridContainer()
        Игровое поле;


1.buildMessage()
    Получает текст в переменную _messageText от таких методов как:
        renderTurnMessage(), _onOpponentLeft(), _onGameBegin(), а так же при нажатии 'Submit' в виджете  buildInputName().


2.buildInputName()
    При нажатии на кнопку 'Submit' виджет созадет имя игрока и удаляет себя со страницы.
        После создания имени будет выведен текст 'Waiting for an opponent...', а так же показан виджет buildGridContainer().
        Если поле пусто, то при нажатии будет выведено предупреждение.

3.buildGridContainer()
    Игровое поле, которое скрыто до тех пор, пока не будет нажата кнока 'Submit'.

    Виджет выводит массив из 9 карточек с присвоеныным индексом (int positionNum), в которые помещаются сообтветствующие индексу значения из 'Map<dynamic, String> checked'.

    Если ход противника (bool opponentStep = true), то из виджета удается свойство onTap, выставляя bool opponentStep = true , и нажатаия не фиксируются.

    Если ход игрока, то добавляется свойство onTap в котором происходит вызов таких методов как:
        makeMove(), renderTurnMessage(), isGameOver(), setState((){ opponentStep = true })


    
renderTurnMessage( bool myTurn ) - помещает в переменную 'String _messageText' текст с информацией об очереди, в зависимости от значения 'bool myTurn'

isGameOver( Map<dynamic, String> checked ) - Сверяет текущее состояние игрового поля, полученное от метода 'getBoardState()', которое приводится к массиву строк List<String> rows, для поиска совпадений с массивом  List<String> matches, в котром находятся победные комбинации. Если найдено совпадение, то возвращается true. Если совпадений на момент вызова нет, то метод возвращает 'false'. Если все поля заняты, но совпадения не найдено, то в возвращается переменная tie = true.

getBoardState( Map<dynamic, String> checked ) - Принимает текущее состояние поля, возращая новый объект, который  может прочитать метод 'isGameOver()'.

makeMove(int positionNum) - Помещает в ключ ( Map<dynamic, String> checked ), соответсвующий индексу (int positionNum),  символ (String symbol) для отображения на клиенте текущего игрока. Для отправки на сервер, создается новая переменная ('String position') . Если значение ключа в котрый помещается символ не является пустым, то вызывается 'return'. Если значение успешно поместилось, создается json из  {symbol': symbol,  'position': position} и создается событие для сервера 'make.move'.

_connectSocket01() - инициализирует подключение к серверу, после чего начинает прослушиваение событий -  "opponent.left";  "game.begin"; "move.made".

_socketStatus(dynamic data) - обработчик, который воводит информацию о статусе сервера.

_onMoveMade(dynamic data) - обработчик, который принимает информацию о сделаном ходе, помещает, полученный 'position' в (Map<dynamic, String> checked) для отображения на клиенте. а так же выставляет 'opponentStep = false'. Делает проверку на победу и ничью, а так же присвает в '_messageText' соответсвующий текст.

_onOpponentLeft - обработчик, который присвает соответсвующий текс если оппонет отключился.

_onGameBegin(dynamic data) - обработчик, который получает от сервера символ играка (symbol), информацию о очередности хода (myTurn), имя оппонета (opponentName)
