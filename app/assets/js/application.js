var labpages = angular
    .module('labpages', [])
    .factory('config', function () {
        return LabPages;
    })
    .factory('pinger', function($rootScope, config) {
        var ping = function (done, fail, always) {
            $.ajax({ url: '/api/ping', timeout: 10000 })
                .done(done || function () {})
                .fail(fail || function () {})
                .error(fail || function () {})
                .always(always || function () {});
        };

        return {
            interval: config.interval || 60000,

            start: function (done, fail, always) {
                this.intervalId = setInterval(
                    function () {
                        ping(done, fail, always);
                    },
                    this.interval
                );

                ping(done, fail, always);

                return this;
            },

            stop: function () {
                if(this.intervalId !== undefined) {
                    clearInterval(this.intervalId);
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
        };
    })
    .filter('substr', function() {
        return function(input, start, length) {
            return input.substr(start, length);
        }
    });

function LabPagesCtrl($scope, $http, socket, pinger, config) {
    $scope.application = config;
    $scope.repositories = [];
    $scope.socket = {
        connected: false
    };

    $scope.hook = {
        up: false
    };

    pinger.start(
        function() {
            $scope.$apply(function() {
                $scope.hook = {
                    up: true,
                    time: new Date().toLocaleString()
                };
            });
        },
        function() {
            $scope.$apply(function() {
                $scope.hook = {
                    up: false,
                    time: new Date().toLocaleString()
                };
            });
        }
    );

    socket
        .connect()
        .on('open', function () {
            $scope.socket = {
                connected: true,
                time: new Date().toLocaleString()
            };

            socket.emit('repositories');
        })
        .on(['close', 'error'], function (e) {
            $scope.socket = {
                connected: false,
                time: new Date().toLocaleString()
            };

            if(e === undefined) {
                $('#reconnect').removeClass('disabled');
            }
        })
        .on(['repository', 'update'], function (message) {
            var updated = false;

            $scope.socket.time = new Date().toLocaleString();
            message.content.time = new Date().toLocaleString();
            $scope.repositories.forEach(function(repository, key) {
                if(repository.owner === message.content.owner && repository.name === message.content.name) {
                    $scope.repositories[key] = message.content;
                    updated = true;
                }
            });

            if(updated === false) {
                $scope.repositories.push(message.content);
            }
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
            url: '/api/users/' + scope.repository.owner + '/repositories/' + scope.repository.name + '/deploy'
        })
            .success(function() {
                $(event.target).toggleClass('disabled');
            });
    };

    $scope.more = function(scope, event) {
        event.preventDefault();

        $(event.target).nextAll('.commit').toggle();
    };

    $scope.refresh = function(scope, event) {
        event.preventDefault();

    };
}
