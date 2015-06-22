'use strict';

var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var CommentSchema = new Schema({
  blog : { type: mongoose.Schema.ObjectId, ref: 'Blog' },
  ancestors : [{ type: mongoose.Schema.ObjectId, ref: 'Comment' }],
  author: String,
  author_id : { type: mongoose.Schema.ObjectId, ref: 'User' },
  body: String
});

module.exports = mongoose.model('Comment', CommentSchema);