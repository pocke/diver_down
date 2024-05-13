# frozen_string_literal: true

RSpec.describe DiverDown::Web do
  include Rack::Test::Methods

  def app
    @app ||= described_class.new(definition_dir:, module_store:, store:)
  end

  let(:definition_dir) do
    Dir.mktmpdir
  end

  let(:store) do
    DiverDown::Web::DefinitionStore.new
  end

  let(:module_store) do
    module_store_path = Tempfile.new(['test', '.yaml']).path
    DiverDown::Web::ModuleStore.new(module_store_path)
  end

  describe 'GET /' do
    around do |example|
      index_path = File.join(DiverDown::Web::WEB_DIR, 'index.html')
      file_exist = File.exist?(index_path)

      unless file_exist
        # index.html is generated by `pnpn run build`
        FileUtils.mkdir_p(DiverDown::Web::WEB_DIR)
        FileUtils.touch(index_path)
      end

      example.run
    ensure
      File.delete(index_path) unless file_exist
    end

    it 'returns body' do
      get '/'
      expect(last_response.status).to eq(200)
    end
  end

  describe 'GET /api/definitions.json' do
    it 'returns [] if store is blank' do
      get '/api/definitions.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'definitions' => [],
        'pagination' => {
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 0,
          'per' => 100,
        },
      })
    end

    it 'returns definition if store has some definition' do
      definition_1 = DiverDown::Definition.new(
        title: 'title1',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      definition_2 = DiverDown::Definition.new(
        title: 'title2',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'b.rb'
          ),
        ]
      )
      store.set(definition_1, definition_2)
      module_store.set('a.rb', ['A'])

      get '/api/definitions.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'definitions' => [
          {
            'id' => 1,
            'title' => 'title1',
            'definition_group' => nil,
            'sources_count' => 1,
            'unclassified_sources_count' => 0,
          }, {
            'id' => 2,
            'title' => 'title2',
            'definition_group' => nil,
            'sources_count' => 1,
            'unclassified_sources_count' => 1,
          },
        ],
        'pagination' => {
          'current_page' => 1,
          'total_pages' => 1,
          'total_count' => 2,
          'per' => 100,
        },
      })
    end

    describe 'title' do
      def assert_title(title, expected_ids)
        get "/api/definitions.json?title=#{title}"

        definitions = JSON.parse(last_response.body)['definitions']
        ids = definitions.map { _1['id'] }

        expect(ids).to match_array(expected_ids), -> {
          "title: #{title.inspect}\n" \
          "expected_ids: #{expected_ids.inspect}\n" \
          "actual_ids: #{ids.inspect}"
        }
      end

      it 'filters definitions by title=value' do
        definition_1 = DiverDown::Definition.new(
          title: '01234',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'a.rb'
            ),
          ]
        )
        definition_2 = DiverDown::Definition.new(
          title: '56789',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'b.rb'
            ),
          ]
        )

        definition_1_id, definition_2_id = store.set(definition_1, definition_2)

        assert_title 'unknown', []

        # Strict match
        assert_title '01234', [definition_1_id]
        assert_title '56789', [definition_2_id]
        assert_title 'a.rb', []

        # like match
        assert_title '0', [definition_1_id]
        assert_title '1', [definition_1_id]
        assert_title 'a', []
      end
    end

    describe 'source' do
      def assert_source(source, expected_ids)
        get "/api/definitions.json?source=#{source}"

        definitions = JSON.parse(last_response.body)['definitions']
        ids = definitions.map { _1['id'] }

        expect(ids).to match_array(expected_ids), -> {
          "source: #{source.inspect}\n" \
          "expected_ids: #{expected_ids.inspect}\n" \
          "actual_ids: #{ids.inspect}"
        }
      end

      it 'filters definitions by source=value' do
        definition_1 = DiverDown::Definition.new(
          title: '01234',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'a.rb'
            ),
          ]
        )
        definition_2 = DiverDown::Definition.new(
          title: '56789',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'b.rb'
            ),
          ]
        )

        definition_1_id, definition_2_id = store.set(definition_1, definition_2)

        assert_source 'unknown', []

        # Strict match
        assert_source '01234', []
        assert_source 'a.rb', [definition_1_id]
        assert_source 'b.rb', [definition_2_id]

        # like match
        assert_source '0', []
        assert_source 'a', [definition_1_id]
        assert_source 'b.', [definition_2_id]
      end
    end

    describe 'definition_group' do
      def assert_definition_group(definition_group, expected_ids)
        get "/api/definitions.json?definition_group=#{definition_group}"

        definitions = JSON.parse(last_response.body)['definitions']
        ids = definitions.map { _1['id'] }

        expect(ids).to match_array(expected_ids), -> {
          "definition_group: #{definition_group.inspect}\n" \
          "expected_ids: #{expected_ids.inspect}\n" \
          "actual_ids: #{ids.inspect}"
        }
      end

      it 'filters definitions by definition_group=value' do
        definition_1 = DiverDown::Definition.new(
          definition_group: 'group_1',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'a.rb'
            ),
          ]
        )
        definition_2 = DiverDown::Definition.new(
          definition_group: 'group_2',
          sources: [
            DiverDown::Definition::Source.new(
              source_name: 'b.rb'
            ),
          ]
        )

        definition_1_id, definition_2_id = store.set(definition_1, definition_2)

        assert_definition_group 'unknown', []
        assert_definition_group 'group', [definition_1_id, definition_2_id]
        assert_definition_group 'group_1', [definition_1_id]
        assert_definition_group 'group_2', [definition_2_id]
      end
    end
  end

  describe 'GET /api/initialization_status.json' do
    it 'returns { total: 0, loaded: 0 } if store is blank' do
      get '/api/initialization_status.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'total' => 0,
        'loaded' => 0,
      })
    end

    it 'returns loaded size if definition files exist' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      File.write(File.join(definition_dir, '1.yaml'), definition.to_h.to_yaml)

      get '/api/initialization_status.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to match({
        'total' => 1,
        'loaded' => [eq(0), eq(1)].inject(&:or), # It depends on the timing of Thread execution. Since this is a simple test, the or condition was used.
      })
    end
  end

  describe 'GET /api/pid.json' do
    it 'returns pid' do
      get '/api/pid.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'pid' => Process.pid,
      })
    end
  end

  describe 'GET /api/sources.json' do
    it 'returns [] if store is blank' do
      get '/api/sources.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'sources' => [],
      })
    end

    it 'returns definition if store has one definition' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      store.set(definition)

      get '/api/sources.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'sources' => [
          {
            'source_name' => 'a.rb',
          },
        ],
      })
    end
  end

  describe 'GET /api/modules.json' do
    it 'returns [] if store is blank' do
      get '/api/modules.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'modules' => [],
      })
    end

    it 'returns modules' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
          DiverDown::Definition::Source.new(
            source_name: 'b.rb'
          ),
          DiverDown::Definition::Source.new(
            source_name: 'c.rb'
          ),
        ]
      )
      store.set(definition)
      module_store.set('a.rb', ['A', 'B'])
      module_store.set('b.rb', ['B', 'C'])

      get '/api/modules.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'modules' => [
          [
            {
              'module_name' => 'A',
            }, {
              'module_name' => 'B',
            },
          ], [
            {
              'module_name' => 'B',
            }, {
              'module_name' => 'C',
            },
          ],
        ],
      })
    end
  end

  describe 'GET /api/modules/:module_name.json' do
    it 'returns unknown if store is blank' do
      get '/api/modules/unknown.json'

      expect(last_response.status).to eq(404)
    end

    it 'returns module if store has one' do
      definition_1 = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      definition_2 = DiverDown::Definition.new(
        title: 'title 2',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'b.rb'
          ),
        ]
      )

      ids = store.set(definition_1, definition_2)
      module_store.set('a.rb', ['A'])
      module_store.set('b.rb', ['A', 'B'])

      get '/api/modules/A.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'modules' => [
          {
            'module_name' => 'A',
          },
        ],
        'sources' => [
          {
            'source_name' => 'a.rb',
          },
          {
            'source_name' => 'b.rb',
          },
        ],
        'related_definitions' => [
          {
            'id' => ids[0],
            'title' => 'title',
          },
          {
            'id' => ids[1],
            'title' => 'title 2',
          },
        ],
      })

      get '/api/modules/A/B.json'

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'modules' => [
          {
            'module_name' => 'A',
          }, {
            'module_name' => 'B',
          },
        ],
        'sources' => [
          {
            'source_name' => 'b.rb',
          },
        ],
        'related_definitions' => [
          {
            'id' => ids[1],
            'title' => 'title 2',
          },
        ],
      })
    end

    it 'returns module if module_name is escaped' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )

      ids = store.set(definition)
      module_store.set('a.rb', ['グローバル'])

      get "/api/modules/#{CGI.escape('グローバル')}.json"

      expect(last_response.status).to eq(200)
      expect(JSON.parse(last_response.body)).to eq({
        'modules' => [
          {
            'module_name' => 'グローバル',
          },
        ],
        'sources' => [
          {
            'source_name' => 'a.rb',
          },
        ],
        'related_definitions' => [
          {
            'id' => ids[0],
            'title' => 'title',
          },
        ],
      })
    end
  end

  describe 'GET /api/definitions/:id.json' do
    it 'returns 404 if id is not found' do
      get '/api/definitions/0.json'
      expect(last_response.status).to eq(404)
    end

    it 'returns definition if id is found' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      bit_ids = store.set(definition)

      get "/api/definitions/#{bit_ids[0]}.json"

      expect(last_response.status).to eq(200)
      expect(last_response.headers['content-type']).to eq('application/json')
      expect(last_response.body).to include('digraph')
    end

    it 'returns combined definition' do
      definition_1 = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      definition_2 = DiverDown::Definition.new(
        title: 'second title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'b.rb'
          ),
        ]
      )
      bit_ids = store.set(definition_1, definition_2)

      get "/api/definitions/#{bit_ids.inject(0, &:|)}.json"

      expect(last_response.status).to eq(200)
      expect(last_response.headers['content-type']).to eq('application/json')
      expect(last_response.body).to include('digraph')
    end

    it 'returns combined definition with compound=true' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      bit_ids = store.set(definition)

      get "/api/definitions/#{bit_ids.inject(0, &:|)}.json", compound: '1'

      expect(last_response.status).to eq(200)
      expect(last_response.headers['content-type']).to eq('application/json')
      expect(last_response.body).to include('digraph')
      expect(last_response.body).to include('compound')
    end
  end

  describe 'GET /api/sources/:source.json' do
    it 'returns 404 if source is not found' do
      get '/api/sources/unknown.json'

      expect(last_response.status).to eq(404)
    end

    it 'returns response if source is found' do
      definition_1 = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      definition_2 = DiverDown::Definition.new(
        title: 'second title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'b.rb'
          ),
        ]
      )
      store.set(definition_1)
      store.set(definition_2)

      get '/api/sources/a.rb.json'

      expect(last_response.status).to eq(200)
    end
  end

  describe 'POST /api/sources/:source/modules.json' do
    it 'returns 404 if source is not found' do
      post '/api/sources/unknown/modules.json'

      expect(last_response.status).to eq(404)
    end

    it 'set modules if source is found' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      store.set(definition)

      post '/api/sources/a.rb/modules.json', { modules: ['A', 'B'] }

      expect(last_response.status).to eq(200)

      expect(module_store.get('a.rb')).to eq(['A', 'B'])
    end

    it 'ignores blank modules' do
      definition = DiverDown::Definition.new(
        title: 'title',
        sources: [
          DiverDown::Definition::Source.new(
            source_name: 'a.rb'
          ),
        ]
      )
      store.set(definition)

      post '/api/sources/a.rb/modules.json', { modules: ['', 'B'] }

      expect(last_response.status).to eq(200)

      expect(module_store.get('a.rb')).to eq(['B'])
    end
  end
end
