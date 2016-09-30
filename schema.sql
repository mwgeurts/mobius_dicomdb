CREATE TABLE patients (
sopinst varchar(255) primary key,
importdate float,
id varchar(255),
name varchar(255),
birthdate float,
sex varchar(8),
plan varchar(255),
plandate float,
machine varchar(32),
tps varchar(32),
version varchar(32),
type varchar(32),
mode varchar(32),
rxdose float,
fractions float,
doseperfx float,
position varchar(8),
numfiles float
);

.save database.db