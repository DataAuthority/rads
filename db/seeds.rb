# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
RepositoryUser.all.destroy_all
RepositoryUser.create([
                       {
                         name: 'Darrin Mann',
                         email: 'darrin.mann@duke.edu',
                         netid: 'dfm4',
                         is_enabled: true,
                         is_administrator: true
                       },
                       {
                         name: 'Darin London',
                         email: 'darin.london@duke.edu',
                         netid: 'londo003',
                         is_enabled: true,
                         is_administrator: true
                       }
                      ])

