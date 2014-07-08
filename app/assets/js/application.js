var labpages = angular
    .module('labpages', [])
    .factory('config', function () {
        return LabPages;
    })
    .factory('pinger', function($rootScope, config) {
        var ping = function (url, done, fail, always) {
            $.ajax({ url: url, timeout: 10000 })
                .done(done || function () {})
                .fail(fail || function () {})
                .error(fail || function () {})
                .always(always || function () {});
        };

        return {
            intervalId: [],
            interval: config.interval || 60000,

            start: function (url, done, fail, always) {
                this.intervalId[url] = setInterval(
                    function () {
                        ping(url, done, fail, always);
                    },
                    this.interval
                );

                ping(url, done, fail, always);

                return this;
            },

            stop: function (url) {
                if(this.intervalId[url] !== undefined) {
                    clearInterval(this.intervalId[url]);
                }

                return this;
            }
        };
    })
    .factory('socket', function ($rootScope, config) {
        var socket = null,
            listeners = {},
            requests = {},
            message = function(response) {
                response = JSON.parse(response.data);

                if(response.ticket && requests[response.ticket] !== undefined) {
                    $rootScope.$apply(function () {
                        requests[response.ticket].callback(response);
                    });

                    delete requests[response.ticket]
                } else {
                    dispatch(response.type, response);
                }
            },
            dispatch = function (eventName, message) {
                if(listeners[eventName] !== undefined) {
                    listeners[eventName].forEach(function(listener) {
                        $rootScope.$apply(function () {
                            listener(message);
                        });
                    });
                }
            };

        return {
            connect: function () {
                socket = new WebSocket(config.endpoint);

                socket.onopen = function () { dispatch('open'); };
                socket.onerror = function () { dispatch('error', arguments); };
                socket.onclose = function () { dispatch('close'); };
                socket.onmessage = message;

                return this;
            },
            on: function (eventName, callback) {
                if(eventName.constructor.name !== 'Array') {
                    eventName = [eventName];
                }

                eventName.forEach(function(event) {
                    if(listeners[event] === undefined) {
                        listeners[event] = [];
                    }

                    listeners[event].push(callback);
                });


                return this;
            },

            emit: function (eventName, data, callback) {
                var ticket = (new Date()).getTime();

                requests[ticket] = {
                    type: eventName,
                    ticket: ticket,
                    data: data
                };

                socket.send(JSON.stringify(requests[ticket]));

                requests[ticket].callback = callback || function () {};

                return this;
            }
        }
    })
    .filter('substr', function() {
        return function(input, start, length) {
            return input.substr(start, length);
        }
    })
    .directive('moment', [
        '$timeout',
        function($timeout) {
            return {
                restrict: 'E',
                template: '<time>{{fromNow}}</time>',
                replace: true,
                link: function(scope, element, attrs) {
                    var update = function() {
                        var datetime = scope.$eval(attrs.datetime);

                        if(datetime) {
                            element.text(moment(datetime).fromNow());
                            unwatch();
                        }

                        $timeout(update, 10000);
                    };

                    var unwatch = scope.$watch(attrs.datetime, update);
                }
            }
        }
    ]);

function LabPagesCtrl($scope, $http, socket, pinger, config) {
    $scope.application = config;
    $scope.repositories = [];
    $scope.socket = {
        connected: false,
        time: false
    };

    $scope.hook = {
        up: false,
        time: false
    };

    $scope.redis = {
        up: false,
        time: false
    };

    pinger.start(
        '/api/ping',
        function(response) {
            $scope.$apply(function() {
                $scope.hook = {
                    up: response.up,
                    time: new Date().toString(),
                    data: response
                };
            });
        },
        function() {
            $scope.$apply(function() {
                $scope.hook = {
                    up: false,
                    time: new Date().toString()
                };
            });
        }
    );

    pinger.start(
        '/api/ping/redis',
        function(response) {
            $scope.$apply(function() {
                $scope.redis = {
                    up: response.up,
                    time: new Date().toString()
                };
            });
        },
        function() {
            $scope.$apply(function() {
                $scope.redis = {
                    up: false,
                    time: new Date().toString()
                };
            });
        }
    );

    $http({
        method: 'GET',
        url: '/api/repositories'
    })
        .success(function(reponse) {
            reponse.forEach(function(repository) {
                $scope.repositories.push(repository);
            });
        });


    socket
        .connect()
        .on('open', function () {
            $scope.socket = {
                connected: true,
                time: new Date().toString()
            };
        })
        .on(['close', 'error'], function (e) {
            $scope.socket = {
                connected: false,
                time: new Date().toString()
            };

            if(e === undefined) {
                $('#reconnect').removeClass('disabled');
            }
        })
        .on('update', function (message) {
            var updated = false;

            $scope.socket.time = new Date().toString();
            message.content.time = new Date().toString();
            $scope.repositories.forEach(function(repository, key) {
                if(repository.owner === message.content.owner && repository.name === message.content.name) {
                    $scope.repositories[key] = message.content;
                    updated = true;
                }
            });

            if(updated === false) {
                $scope.repositories.push(message.content);
            }
        })
        .on('delete', function (message) {
            $scope.repositories.forEach(function(repository, key) {
                if(repository.owner === message.content.owner && repository.name === message.content.name) {
                    $scope.repositories.splice(key, 1);
                }
            });
        });

    $scope.reconnect = function(scope, event) {
        $(event.target).toggleClass('disabled');

        socket.connect();
    };

    $scope.deploy = function(scope, event) {
        event.preventDefault();

        $(event.target).toggleClass('disabled');

        $http({
            method: 'GET',
            url: '/api/users/' + scope.repository.owner + '/' + scope.repository.name + '/deploy'
        })
            .success(function() {
                $(event.target).toggleClass('disabled');
            });
    };

    $scope.refresh = function(scope, event) {
        event.preventDefault();

        $(event.target).toggleClass('disabled');

        $http({
            method: 'GET',
            url: '/api/users/' + scope.repository.owner + '/' + scope.repository.name + '/update'
        })
            .success(function() {
                $(event.target).toggleClass('disabled');
            });
    };

    $scope.delete = function(scope, event) {
        event.preventDefault();

        $(event.target).toggleClass('disabled');

        $http({
            method: 'GET',
            url: '/api/users/' + scope.repository.owner + '/' + scope.repository.name + '/delete'
        })
            .success(function() {
                $(event.target).toggleClass('disabled');
            });
    };
}
