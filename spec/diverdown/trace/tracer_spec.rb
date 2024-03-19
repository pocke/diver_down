# frozen_string_literal: true

RSpec.describe Diverdown::Trace::Tracer do
  describe '#initialize' do
    describe 'with relative path target_files' do
      it 'raises ArgumentError' do
        expect {
          described_class.new(
            target_files: ['relative/path']
          )
        }.to raise_error(ArgumentError, /target_files must be absolute path/)
      end
    end
  end

  describe '#trace' do
    describe 'when tracing script' do
      # @param path [String]
      # @return [Diverdown::Definition]
      def trace_fixture(path, module_set: [], target_files: nil, filter_method_id_path: nil, module_finder: nil)
        # NOTE: Script need to define .run method
        script = fixture_path(path)
        load script, AntipollutionModule
        antipollution_environment = AntipollutionKlass.allocate

        tracer = described_class.new(
          module_set:,
          target_files:,
          filter_method_id_path:,
          module_finder:
        )

        tracer.trace(
          title: 'title'
        ) do
          antipollution_environment.send(:run)
        end
      end

      # fill default values
      def fill_default(hash)
        hash[:title] ||= ''
        hash[:sources] ||= []
        hash[:sources].each do |source|
          source[:dependencies] ||= []
          source[:modules] ||= []

          source[:dependencies].each do |dependency|
            dependency[:method_ids] ||= []
          end
        end
        hash
      end

      before do
        stub_const('AntipollutionModule', Module.new)
        stub_const('AntipollutionKlass', Class.new)

        AntipollutionKlass.include(AntipollutionModule)
      end

      it 'traces tracer_module.rb' do
        definition = trace_fixture(
          'tracer_module.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::B',
                  method_ids: [
                    {
                      context: 'class',
                      name: 'call_c',
                      paths: [
                        match('tracer_module.rb:8'),
                      ],
                    },
                  ],
                },
              ],
            }, {
              source_name: 'AntipollutionModule::B',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::C',
                  method_ids: [
                    {
                      context: 'class',
                      name: 'call_d',
                      paths: [
                        match('tracer_module.rb:14'),
                      ],
                    },
                  ],
                },
              ],
            }, {
              source_name: 'AntipollutionModule::C',
            },
          ]
        ))
      end

      it 'traces tracer_module.rb with module_finder' do
        definition = trace_fixture(
          'tracer_module.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
          ],
          module_finder: ->(source) {
            case source.source_name
            when 'AntipollutionModule::A'
              ['A', 'B']
            when 'AntipollutionModule::B'
              ['C']
            end
          }
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::B',
                  method_ids: [
                    {
                      context: 'class',
                      name: 'call_c',
                      paths: [
                        match('tracer_module.rb:8'),
                      ],
                    },
                  ],
                },
              ],
              modules: [
                {
                  module_name: 'A',
                }, {
                  module_name: 'B',
                },
              ],
            }, {
              source_name: 'AntipollutionModule::B',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::C',
                  method_ids: [
                    {
                      context: 'class',
                      name: 'call_d',
                      paths: [
                        match('tracer_module.rb:14'),
                      ],
                    },
                  ],
                },
              ],
              modules: [
                {
                  module_name: 'C',
                },
              ],
            }, {
              source_name: 'AntipollutionModule::C',
            },
          ]
        ))
      end

      it 'traces tracer_module.rb with target_files' do
        definition = trace_fixture(
          'tracer_module.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
          ],
          target_files: []
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [],
            }, {
              source_name: 'AntipollutionModule::B',
              dependencies: [],
            }, {
              source_name: 'AntipollutionModule::C',
            },
          ]
        ))
      end

      it 'traces tracer_class.rb' do
        definition = trace_fixture(
          'tracer_class.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
            'AntipollutionModule::D',
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::B',
                  method_ids: [
                    {
                      name: 'call_c',
                      context: 'class',
                      paths: [
                        match(/tracer_class\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::B',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::C',
                  method_ids: [
                    {
                      name: 'call_d',
                      context: 'class',
                      paths: [
                        match(/tracer_class\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::C',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::D',
                  method_ids: [
                    {
                      name: 'name',
                      context: 'class',
                      paths: [
                        match(/tracer_class\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::D',
            },
          ]
        ))
      end

      it 'traces tracer_class.rb with filter path' do
        definition = trace_fixture(
          'tracer_class.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
            'AntipollutionModule::D',
          ],
          filter_method_id_path: ->(path) {
            path.gsub(fixture_path(''), '')
          }
        )

        paths = definition.sources.flat_map(&:dependencies).flat_map(&:method_ids).flat_map(&:paths)
        expect(paths).to all(match(/^tracer_class\.rb:\d+/))
      end

      it 'traces tracer_instance.rb' do
        definition = trace_fixture(
          'tracer_instance.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::B',
            'AntipollutionModule::C',
            'AntipollutionModule::D',
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::B',
                  method_ids: [
                    {
                      name: 'call_c',
                      context: 'instance',
                      paths: [
                        match(/tracer_instance\.rb:\d+/),
                      ],
                    },
                    {
                      name: 'new',
                      context: 'class',
                      paths: [
                        match(/tracer_instance\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::B',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::C',
                  method_ids: [
                    {
                      name: 'call_d',
                      context: 'instance',
                      paths: [
                        match(/tracer_instance\.rb:\d+/),
                      ],
                    },
                    {
                      name: 'new',
                      context: 'class',
                      paths: [
                        match(/tracer_instance\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::C',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::D',
                  method_ids: [
                    {
                      name: 'name',
                      context: 'class',
                      paths: [
                        match(/tracer_instance\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::D',
            },
          ]
        ))
      end

      it 'traces tracer_subclass.rb' do
        definition = trace_fixture(
          'tracer_subclass.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::D',
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::B',
                  method_ids: [
                    {
                      name: 'call_c',
                      context: 'instance',
                      paths: [
                        match(/tracer_subclass\.rb:\d+/),
                      ],
                    },
                    {
                      name: 'new',
                      context: 'class',
                      paths: [
                        match(/tracer_subclass\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::B',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::C',
                  method_ids: [
                    {
                      name: 'call_d',
                      context: 'instance',
                      paths: [
                        match(/tracer_subclass\.rb:\d+/),
                      ],
                    },
                    {
                      name: 'new',
                      context: 'class',
                      paths: [
                        match(/tracer_subclass\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::C',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::D',
                  method_ids: [
                    {
                      name: 'new',
                      context: 'class',
                      paths: [
                        match(/tracer_subclass\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::D',
            },
          ]
        ))
      end

      it 'traces tracer_separated_file.rb' do
        stub_const('::A', Class.new)
        stub_const('::B', Class.new)
        stub_const('::C', Class.new)

        definition = trace_fixture(
          'tracer_separated_file.rb',
          module_set: [
            '::A',
            '::C',
          ],
          target_files: [
            fixture_path('tracer_separated_file.rb'),
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'A',
              dependencies: [
                {
                  source_name: 'C',
                  method_ids: [
                    {
                      name: 'name',
                      context: 'class',
                      paths: [
                        match(/tracer_separated_file\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'C',
            },
          ]
        ))
      end

      it 'traces tracer_deep_stack.rb' do
        definition = trace_fixture(
          'tracer_deep_stack.rb',
          module_set: [
            'AntipollutionModule::A',
            'AntipollutionModule::D',
          ]
        )

        expect(definition.to_h).to match(fill_default(
          title: 'title',
          sources: [
            {
              source_name: 'AntipollutionModule::A',
              dependencies: [
                {
                  source_name: 'AntipollutionModule::D',
                  method_ids: [
                    {
                      name: 'name',
                      context: 'class',
                      paths: [
                        match(/tracer_deep_stack\.rb:\d+/),
                      ],
                    },
                  ],
                },
              ],
            },
            {
              source_name: 'AntipollutionModule::D',
            },
          ]
        ))
      end

      # For optimize
      # it 'traces tracer_deep_stack.rb fast' do
      #   require 'benchmark'
      #
      #   without_trace = Benchmark.realtime do
      #     mod = Module.new
      #     k = Class.new
      #     k.include(mod)
      #     load(fixture_path('tracer_deep_stack.rb'), mod)
      #     k.allocate.send(:run)
      #   end
      #
      #   with_trace = Benchmark.realtime do
      #     # NOTE: Script need to define .run method
      #     script = fixture_path('tracer_deep_stack.rb')
      #     load script, AntipollutionModule
      #     antipollution_environment = AntipollutionKlass.allocate
      #
      #     tracer = described_class.new(
      #       title: 'title',
      #       module_set: [
      #         AntipollutionModule::A,
      #         AntipollutionModule::D,
      #       ]
      #     )
      #
      #     tracer.trace(title: '') do
      #       antipollution_environment.send(:run)
      #     end
      #   end
      #
      #   puts "#{with_trace / without_trace} times slower"
      # end
    end
  end
end
