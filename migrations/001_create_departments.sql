-- Миграция: создание таблицы отделов и внешнего ключа

CREATE TABLE IF NOT EXISTS departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    region VARCHAR(50)
);

ALTER TABLE documents ADD COLUMN IF NOT EXISTS department_id INT;

ALTER TABLE documents 
  ADD CONSTRAINT fk_department 
  FOREIGN KEY (department_id) 
  REFERENCES departments(id);
