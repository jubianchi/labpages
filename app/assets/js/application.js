(function(window) {
    var $ = window.jQuery,
        check = function() {
            var $hook = $('#hook'),
                $h6 = $('h6', $hook),
                $status = $('.status', $hook),
                df = $.Deferred();

            $h6.html('Checking LabPages Web Hook status...');

            $.ajax({
                url: '/api/ping',
                timeout: 10000
            })
                .done(function(data) {
                    $('#hook').removeClass('alert-danger').addClass('alert-success');
                    $h6.html(data.message + ' <small>(jobs: ' + data.sidekiq.processed + '/' + data.sidekiq.failed + ')</small>');
                    $status.html('');
                })
                .fail(function() {
                    $('#hook').removeClass('alert-success').addClass('alert-danger');
                    $h6.html('LabPages Web Hook is down :-(');
                })
                .error(function(xhr, err) {
                    switch(err) {
                        case 'abort':
                            $status.html('<strong>Request was aborted</strong><br/>');
                            break;
                        case 'timeout':
                            $status.html('<strong>Request timed-out after 10 seconds</strong><br/>');
                            break;
                        default:
                            $status.html('<strong>No response from sevrer (' + err + ')</strong><br/>');
                            break;
                    }
                })
                .always(function() {
                    $status.html($status.html() + '<small>Last ping on ' + new Date().toLocaleString() + '</small>');
                    df.resolve();
                })

            return df.promise();
        },
        panel = function(repository, gitlabUrl) {
            var cls = 'danger',
                panel = $('<div/>').attr('id', repository.owner + '-' + repository.name);

            $('#' + repository.owner + '-' + repository.name).remove();

            panel
                .addClass('panel')
                .append(
                    $('<div/>')
                        .addClass('panel-heading')
                        .append(
                            $('<h3/>')
                                .append(
                                    $('<a/>')
                                        .attr('href', '//' + repository.owner + '.' + gitlabUrl + '/' + repository.name)
                                        .text(' ' + repository.owner + ' / ' + repository.name)
                                )
                                .addClass('panel-title')
                        )
                );

            if(repository.refs.deployed && repository.refs.remote) {
                panel.append(commits(repository, gitlabUrl));

                cls = 'warning';
                if(repository.refs.deployed[0] === repository.refs.remote[0]) {
                    cls = 'success';
                } else {
                    panel
                        .append(
                            $('<div/>')
                                .addClass('panel-footer')
                                .addClass('clearfix')
                                .append(
                                    $('<a/>')
                                        .addClass('btn')
                                        .addClass('btn-small')
                                        .addClass('btn-success')
                                        .addClass('pull-right')
                                        .addClass('deploy')
                                        .text('Deploy')
                                )
                        );
                }
            } else {
                panel
                    .append($('<p/>').text('Can\'t determine page status...'))
                    .append($('<pre/>').text(repository.error))
            }

            return panel.addClass('panel-' + cls);
        },
        commits = function(repository, gitlabUrl) {
            var elems = [];

            if(repository.refs.remote && (!repository.refs.deployed || repository.refs.remote[0] != repository.refs.deployed[0])) {
                elems.push($('<h6>').text('Remote'));
                elems.push(commit(repository, repository.refs.remote, gitlabUrl));
            }

            if(repository.refs.commits.length) {
                if(repository.refs.commits.length > 1) {
                    elems.push(
                        $('<span/>')
                            .addClass('btn')
                            .addClass('btn-default')
                            .addClass('btn-more')
                            .append($('<strong/>').text(repository.refs.commits.length + ' more commits...'))
                    );
                }

                repository.refs.commits.forEach(function(cm) {
                    cm = commit(repository, cm, gitlabUrl);

                    if(repository.refs.commits.length > 1) {
                        cm.addClass('commit');
                    }

                    elems.push(cm);
                });
            }

            if(repository.refs.deployed) {
                elems.push($('<h6>').text('Deployed'));
                elems.push(commit(repository, repository.refs.deployed, gitlabUrl));
            }

            return elems;
        },
        commit = function(repository, ref, gitlabUrl) {
            return $('<div/>')
                .addClass('well')
                .append(
                    $('<div/>')
                        .addClass('row')
                        .append(
                            $('<img/>')
                                .addClass('avatar')
                                .addClass('pull-left')
                                .attr('src', 'http://www.gravatar.com/avatar/' + ref[4])
                        )
                        .append(
                            $('<p/>')
                                .addClass('pull-left')
                                .append($('<strong/>').text(ref[1]))
                                .append($('<br/>'))
                                .append(
                                    $('<a/>')
                                        .attr('href', '//' + gitlabUrl + '/u/' + ref[3])
                                        .text(ref[3])
                                )
                                .append(' authored ' + ref[2])
                        )
                        .append(
                            $('<p/>')
                                .addClass('pull-right')
                                .append(
                                    $('<a/>')
                                        .addClass('btn')
                                        .addClass('btn-default')
                                        .attr('href', '//' + gitlabUrl + '/' + repository.owner + '/' + repository.name + '/commit/' + ref[0])
                                        .text(' ' + ref[0].substr(0, 9))
                                        .prepend($('<i/>').addClass('icon-eye-open').addClass('icon-large'))
                                )
                        )
                );
        },
        init = function(gitlabUrl) {
            var df = $.Deferred();

            $('hr').nextAll('.panel').remove();

            $.ajax('/api/users')
                .done(function(users) {
                    users.forEach(function(user) {
                        $.ajax('/api/users/' + user.name + '/repositories')
                            .done(function(repositories) {
                                repositories.forEach(function(repository) {
                                    $('hr').after(panel(repository, gitlabUrl));
                                });

                                df.resolve();
                            })
                    })
                });

            return df.promise();
        };

    $(function() {
        $.ajaxSetup({ cache: false });

        check()
            .then(function() {
                var $hook = $('#hook'),
                    $btn = $('.btn', $hook),
                    $pre = $('pre', $hook);

                $btn.click(function() {
                    if($pre.css('display') === 'block') {
                        $pre.toggle();
                    } else {
                        $.get('/api/log', function(data) { $pre.html(data).toggle(); });
                    }
                });

                setInterval(check, 60000);
            })
            .then(function() {
                var connect = function() {
                    var df = $.Deferred();
                        ws = new WebSocket('ws://' + window.location.host + window.location.pathname);
                    ws.onopen = function() {
                        ws.send(JSON.stringify({
                            'type': 'repositories'
                        }));

                        $('#socket').addClass('alert-success').removeClass('alert-danger');

                        df.resolve();
                    };

                    ws.onclose = function() {
                        $('.btn-reconnect').show();
                        $('#socket').addClass('alert-danger').removeClass('alert-success');
                    };

                    ws.onmessage = function(msg) {
                        msg = JSON.parse(msg.data);

                        if(msg.type === 'update') {
                            $('hr').after(panel(msg.content, gitlabUrl));
                        }

                        $('h1').html('LabPages - Status <small>' + new Date().toLocaleString() + '</small>');
                    };

                    return df;
                };

                $('body').delegate('.btn-reconnect', 'click', function() {
                    $(this).addClass('disabled');

                    connect().then(function() {
                        $('.btn-reconnect').removeClass('disabled').hide();
                    });
                });
                connect();


                $('body').delegate('.deploy', 'click', function() {
                    var info = $(this).parents('.panel').attr('id').split('-'),
                        owner = info[0],
                        repository = info[1],
                        btn = $(this);

                    btn.addClass('disabled');

                    $.ajax('/api/users/' + owner + '/repositories/' + repository + '/deploy')
                        .fail(function(data) {
                            btn.removeClass('disabled');
                        });
                });

                $('body').delegate('.btn.log', 'click', function() {
                    $(this).parents('pre.log').toggle();
                });

                $('body').delegate('.btn-more', 'click', function() {
                    $(this).nextAll('.commit').toggle();
                });
            });
    });
})(window);
