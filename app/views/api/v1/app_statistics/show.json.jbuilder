json.id @app.id
json.name @app.name
json.unresolved_problems_count do
  json.merge! @app.problems.unresolved.group(:environment).count
end
