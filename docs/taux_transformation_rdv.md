# Taux RDV confirmé → commande

`heroku run rails c` puis coller.

Dénominateur : RDV **confirmés avec client**, hors clients test `2` et `1822`. Transformé = ce client a au moins une commande.

```ruby
CLIENTS_TEST = [2, 1822]
rdvs = DemandeRdv.where(statut: "confirmé")
                 .joins(:meeting)
                 .where.not(meetings: { client_id: nil })
                 .where.not(meetings: { client_id: CLIENTS_TEST })
n_rdv = rdvs.count
n_convertis = 0
commande_ids = []

rdvs.find_each do |rdv|
  ids = Commande.where(client_id: rdv.meeting.client_id).pluck(:id)
  ids << rdv.meeting.commande_id if rdv.meeting.commande_id
  ids = Commande.where(id: ids.compact.uniq).where.not(client_id: CLIENTS_TEST).pluck(:id)
  next if ids.empty?
  n_convertis += 1
  commande_ids.concat(ids)
end

commande_ids.uniq!
vol_articles = Article.where(commande_id: commande_ids).sum(:total).to_d
vol_sous = Sousarticle.joins(:article).where(articles: { commande_id: commande_ids }).sum(:prix).to_d

puts "rdv_confirmes_avec_client: #{n_rdv}"
puts "rdv_convertis: #{n_convertis}"
puts "taux: #{n_rdv.zero? ? 0 : (100.0 * n_convertis / n_rdv).round(1)} %"
puts "commandes_liees: #{commande_ids.size}"
puts "volume_ttc: #{(vol_articles + vol_sous).round(2)}"
```


rdv_confirmes_avec_client: 142
rdv_convertis: 82
taux: 57.7 %
commandes_liees: 82
volume_ttc: 48805.0
=> nil