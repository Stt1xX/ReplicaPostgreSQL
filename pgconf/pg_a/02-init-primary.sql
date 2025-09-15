-- Выполняется при инициализации PRIMARY
CREATE ROLE replicator WITH REPLICATION PASSWORD 'replpass' LOGIN;


-- Настройка тестовой БД и таблиц для демонстрации записи/репликации
CREATE DATABASE demo;
\connect demo


CREATE TABLE IF NOT EXISTS accounts (id serial primary key, name text, balance int);
CREATE TABLE IF NOT EXISTS logs (id serial primary key, note text, created_at timestamptz default now());


INSERT INTO accounts (name, balance) VALUES ('alice', 100), ('bob', 50);
INSERT INTO logs (note) VALUES ('init1'),('init2');