require 'spec_helper'

describe Generator, '#to_sql' do
  subject { object.to_sql }

  let(:klass)         { Generator                                        }
  let(:id)            { Attribute::Integer.new(:id)                      }
  let(:name)          { Attribute::String.new(:name)                     }
  let(:age)           { Attribute::Integer.new(:age, :required => false) }
  let(:header)        { [ id, name, age ]                                }
  let(:body)          { [ [ 1, 'Dan Kubb', 35 ] ].each                   }
  let(:base_relation) { BaseRelation.new('users', header, body)          }
  let(:object)        { klass.new                                        }

  before do
    @original = object.to_sql
  end

  context 'when no object visited' do
    it_should_behave_like 'an idempotent method'

    it { should_not be_frozen }

    it { should == '' }
  end

  context 'when a base relation is visited' do
    before do
      object.visit(base_relation)
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users"' }
  end

  context 'when a projection is visited' do
    before do
      object.visit(base_relation.project([ :id, :name ]))
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name" FROM "users"' }
  end

  context 'when a rename is visited' do
    before do
      object.visit(base_relation.rename(:id => :user_id))
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id" AS "user_id", "users"."name", "users"."age" FROM "users"' }
  end

  context 'when a restriction is visited' do
    context 'and the predicate is equality' do
      context 'and the value is not nil' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].eq(1) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" = 1' }
      end

      context 'and the value is nil' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].eq(nil) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" IS NULL' }
      end
    end

    context 'and the predicate is inequality' do
      context 'and the left attribute is optional' do
        before do
          object.visit(base_relation.restrict { |r| r[:age].ne(1) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE ("users"."age" <> 1 OR "users"."age" IS NULL)' }
      end

      context 'and the right attribute is optional' do
        before do
          object.visit(base_relation.restrict { |r| Logic::Predicate::Inequality.new(1, r[:age]) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE (1 <> "users"."age" OR "users"."age" IS NULL)' }
      end

      context 'and the left is a value' do
        before do
          object.visit(base_relation.restrict { |r| Logic::Predicate::Inequality.new(1, r[:id]) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE 1 <> "users"."id"' }
      end

      context 'and the right is a value' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].ne(1) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" <> 1' }
      end

      context 'and the right is a nil value' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].ne(nil) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" IS NOT NULL' }
      end
    end

    context 'and the predicate is greater than' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].gt(1) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" > 1' }
    end

    context 'and the predicate is greater than or equal to' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].gte(1) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" >= 1' }
    end

    context 'and the predicate is less than' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].lt(1) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" < 1' }
    end

    context 'and the predicate is less than or equal to' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].lte(1) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" <= 1' }
    end

    context 'and the predicate is inclusion' do
      context 'using an Enumerable' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].include([ 1, 2 ]) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" IN (1, 2)' }
      end

      context 'using an inclusive Range' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].include(1..10) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" BETWEEN 1 AND 10' }
      end

      context 'using an exclusive Range' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].include(1...10) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE ("users"."id" >= 1 AND "users"."id" < 10)' }
      end
    end

    context 'and the predicate is exclusion' do
      context 'using an Enumerable' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].exclude([ 1, 2 ]) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" NOT IN (1, 2)' }
      end

      context 'using an inclusive Range' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].exclude(1..10) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE "users"."id" NOT BETWEEN 1 AND 10' }
      end

      context 'using an exclusive Range' do
        before do
          object.visit(base_relation.restrict { |r| r[:id].exclude(1...10) })
        end

        it_should_behave_like 'a generated SQL query'

        it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE ("users"."id" < 1 OR "users"."id" >= 10)' }
      end
    end

    context 'and the predicate is a conjunction' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].gte(1).and(r[:id].lt(10)) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE ("users"."id" >= 1 AND "users"."id" < 10)' }
    end

    context 'and the predicate is a disjunction' do
      before do
        object.visit(base_relation.restrict { |r| r[:id].gte(1).or(r[:id].lt(10)) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE ("users"."id" >= 1 OR "users"."id" < 10)' }
    end

    context 'and the predicate is a negation' do
      before do
        object.visit(base_relation.restrict { |r| Logic::Connective::Negation.new(r[:id].eq(1)) })
      end

      it_should_behave_like 'a generated SQL query'

      it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" WHERE NOT "users"."id" = 1' }
    end
  end

  context 'when an order is visited' do
    before do
      object.visit(base_relation.order)
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" ORDER BY "users"."id", "users"."name", "users"."age"' }
  end

  context 'when a reverse is visited' do
    before do
      object.visit(base_relation.order.reverse)
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" ORDER BY "users"."id" DESC, "users"."name" DESC, "users"."age" DESC' }
  end

  context 'when a limit is visited' do
    before do
      object.visit(base_relation.order.take(1))
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" ORDER BY "users"."id", "users"."name", "users"."age" LIMIT 1' }
  end

  context 'when an offset is visited' do
    before do
      object.visit(base_relation.order.drop(1))
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT "users"."id", "users"."name", "users"."age" FROM "users" ORDER BY "users"."id", "users"."name", "users"."age" OFFSET 1' }
  end

  context 'when a base relation name has a quote' do
    let(:base_relation) { BaseRelation.new('"users"', header, body) }

    before do
      object.visit(base_relation)
    end

    it_should_behave_like 'a generated SQL query'

    it { should == 'SELECT DISTINCT """users"""."id", """users"""."name", """users"""."age" FROM """users"""' }
  end
end
