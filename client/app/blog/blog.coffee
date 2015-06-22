'use strict'

angular.module 'mitchDzuganApp'
.config ($stateProvider) ->
  $stateProvider
  .state 'blog',
    url: '/blog'
    templateUrl: 'app/blog/home/home.html'
    controller: 'BlogHomeCtrl'
  .state 'blog-new',
    url: '/blog/new'
    templateUrl: 'app/blog/new/new.html'
    controller: 'BlogNewCtrl'
  .state 'blog-single',
    url: '/blog/:id'
    templateUrl: 'app/blog/single/single.html'
    controller: 'BlogSingleCtrl'
  .state 'blog-edit',
    url: '/blog/:id/edit'
    templateUrl: 'app/blog/single/edit.html'
    controller: 'BlogEditCtrl'
