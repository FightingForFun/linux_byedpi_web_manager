ByeDPI Web Manager (для Linux / Docker)

Краткое описание:
- Генератор стратегий обхода блокировок.
- Проверка стратегий через указанные или выбранные URL-адреса.
- Управление процессами ByeDPI для постоянного использования.

Требования:
- PHP версия 8.0.0 и выше.
- Обязательные расширения PHP:
  - extension=curl
  - extension=openssl
- Стандартные PHP-функции (обычно включены по умолчанию):
  - file_get_contents, file_put_contents, file, chmod, exec, shell_exec, readlink
- Полная версия LSOF (не из BusyBox).
- Системные утилиты (обычно доступны по умолчанию): 
  - nohup, kill
- Доступ к /proc
- Актуальные корневые сертификаты (ca-certificates).
- Понимание, что такое SOCKS5 и PAC, и как пользоваться вкладкой "Сеть" в любом браузере (F12).

Настройка:
- config.json
  - Настройка IP для запуска процесса (Установлены значения по умолчанию).
  - Настройка IP для PAC файла и отображения в скрипте (Установлены значения по умолчанию).
  - Настройка портов (при конфликтах с другими приложениями) (Установлены значения по умолчанию).
  - Настройка групп ссылок по умолчанию.

Функционал:
- Автоматическая проверка требований: ОС, PHP, утилиты, файлы.
- Автоматическое назначение прав доступа к файлам.
- Определение серверов Google Global Cache (GGC).
- Мониторинг портов и процессов ciadpi.

- Генерация стратегий на основе весовых коэффициентов для аргументов и флагов.
- Ручной/автоматический ввод URL для проверки стратегий.
- Настройка параметров php_curl.
- Многопоточная проверка стратегий (1-24 потока).
- Фильтрация по проценту успешных запросов.

- 8 блоков (процессов) "для использования".
- Применение стратегии.
- Запустить / остановить процесс.
- Запущен / остановлен процесс.
- Ввод доменов / поддомен+домен для PAC и хост листа.
- Использовать / не использовать хост лист.
- PAC файл, распределяющий запросы по 8 процессам.
- Прямое SOCKS5 подключение к каждому из этих 8 процессов.
- ByeDPI 0.17 (x86_64) в комплекте.

Подключение к процессам "для использования":
- SOCKS5 без списка хостов:
  - Весь сетевой трафик будет проксироваться через один конкретный процесс.
  - Есть вероятность, что одно будет разблокировано, а другое сломается.
  - Придется искать одну команду, чтобы разблокировать все интересующее.
  
- SOCKS5 со списком хостов:
  - Сетевой трафик будет идти "как обычно", за исключением указанных хостов, которые будут проксироваться через один конкретный процесс.
  - Придется искать одну команду, чтобы разблокировать все интересующее.
  
- PAC (рекомендуется):
  - Сетевой трафик будет идти "как обычно", за исключением указанных хостов, которые будут проксироваться через все запущенные процессы.
  - Можно распределить хосты по стратегиям (стратегии по хостам).
  - Например, один процесс с одной стратегией разблокирует NNMclub, RuTracker, Instagram, а другой процесс с другой стратегией разблокирует ntc.party, Twitter, Facebook и т.д.
  - Не придется искать одну команду, чтобы разблокировать все интересующее.
  - Работает даже на телевизоре.

Пы-сы: 
- Перед тестированием скрипта:
  - Отключите все SOCKS5-прокси, VPN, PAC-скрипты и другие методы обхода блокировок как в системе, так и в браузере.
  - В противном случае проверка стратегий будет некорректной.
  
- Рекомендуемая среда:
  - Docker.
  - Лучше развернуть контейнер на отдельном устройстве (роутер, NAS или другой ПК).

- Настройка прокси на клиентах:
  - Для ПК:
    - После применения SOCKS5/PAC перезагрузите браузер, чтобы настройки вступили в силу. 
  - Для телефона/TV:
    - После применения SOCKS5/PAC отключите и снова включите Wi-Fi для активации новых параметров.

- Проверка стратегий:
  - Чем больше ссылок вы добавляете, тем дольше ожидаются результаты (25 ссылок ≈ 1 минута).

- Google Global Cache:
  - Текущие GGC-серверы отображаются в разделе «Ссылки для проверки стратегий». Ошибки определения не влияют на работу скрипта.
  - Разные GGC-серверы также отображаются в разделе «Ссылки для проверки стратегий». 

Docker:
- Dockerfile:
  - Устанавливается Lighttpd, PHP, Lsof, Bash, ca-certificates + интернет для загрузки byedpi-17-*.

- IP-адреса:
  - Для доступа извне для PAC замените в config.json в "ip_для_сайта_и_pac_файла" на IP контейнера.
  
- Порты по умолчанию:
  - 20000 — веб-панель.
  - 20001-20008 — ciadpi "для использования".
  - Убедитесь, что порты свободны, или измените их в config.json и Dockerfile.
  
- Сборка:
  - docker build --build-arg ARCH=aarch64 -t byedpi-web-manager .
  - docker build --build-arg ARCH=armv6 -t byedpi-web-manager .
  - docker build --build-arg ARCH=armv7l -t byedpi-web-manager .
  - docker build --build-arg ARCH=x86_64 -t byedpi-web-manager .

- Сохранение:
  - docker save -o byedpi-web-manager.tar byedpi-web-manager

- Запуск:
  - docker run -d -p 20000-20008:20000-20008 --name byedpi-web-manager-container byedpi-web-manager   

- Веб панель:
  - http://{docker_ip}:20000/ 

Интерфейс:
- Можно посмотреть в https://github.com/FightingForFun/linux_byedpi_web_manager/blob/main/screenshot.png

Обсуждение:
- тут в Discussions или в: https://ntc.party/t/byedpi-web-manager-windows-linux/16575