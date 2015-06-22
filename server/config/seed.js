/**
 * Populate DB with sample data on server start
 * to disable, edit config/environment/index.js, and set `seedDB: false`
 */

'use strict';

var Thing = require('../api/thing/thing.model');
var User = require('../api/user/user.model');
var Blog = require('../api/blog/blog.model');
var Comment = require('../api/comment/comment.model');

Thing.find({}).remove(function() {
  Thing.create({
    name : 'Development Tools',
    info : 'Integration wiint, Node Inspector, Livereload, Protractor, Jade, Stylus, Sass, CoffeeScript, and Less.'
  }, {
    name : 'Server and Client integration',
    info : 'Built with a powerful and fun stack: MongoDB, Express, AngularJS, and Node.'
  }, {
    name : 'Smart Build System',
    info : 'Build system ignores `spec`tic injection of scripts and styles into your index.html'
  },  {
    name : 'Modular Structure',
    info : 'Best practice client and server structures allow for more code reusability and maximum scalability'
  },  {
    name : 'Optimized Build',
    info : 'Build process packs up your templates as a single Javaes, and rewrites asset names for caching.'
  },{
    name : 'Deployment Ready',
    info : 'Easily deploy your app to Heroku or Openshift with the heroku and openshift subgenerators'
  });
});

User.find({}).remove(function() {
  User.create({
    provider: 'local',
    name: 'Test User',
    email: 'test@test.com',
    password: 'test'
  }, {
    provider: 'local',
    role: 'admin',
    name: 'Admin',
    email: 'admin@admin.com',
    password: 'admin'
  }, function() {
      console.log('finished populating users');
    }
  );
});

Blog.find({}).remove(function() {});
Comment.find({}).remove(function() {});

var b = new Blog({
  title: "Ayyy",
  body: "Lmao",
  root_comments: []
});
b.save(function(e) {
  var c = new Comment({
    blog: b._id,
    ancestors: [],
    author: "Me",
    body: "Don't care"
  });
  c.save(function(e) {
    var d = new Comment({
      blog: b._id,
      ancestors: [c._id],
      author: "OTHER GUY",
      body: "THIS IS A 2nd COMMENT"
    });
    d.save(function(e) {
      console.log("Done saving stuff");
      Blog.find()
          .populate('root_comments')
          .exec(function(err, blogs) {
            console.log(blogs);
          });
    });
  })
});