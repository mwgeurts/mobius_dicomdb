CREATE TABLE patients (
uid varchar(255) primary key,
importdate float,
id varchar(255),
name varchar(255),
birthdate float,
sex varchar(16),
plan varchar(255),
plandate float,
machine varchar(16),
tps varchar(16),
version varchar(16),
type varchar(16),
mode varchar(16),
rxdose float,
fractions float,
doseperfx float,
position varchar(16),
sopinst blob,
dicomfiles blob
);

.save database.db