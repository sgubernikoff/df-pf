class CreateJoinTableVisitDress < ActiveRecord::Migration[7.1]
  def change
    create_join_table :visits, :dresses do |t|
      t.index [:visit_id, :dress_id]
      t.index [:dress_id, :visit_id]
    end
  end
end
