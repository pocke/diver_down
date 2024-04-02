import { ComponentProps, FC, useCallback, useMemo, useState } from 'react'
import styled from 'styled-components'

import { Link } from '@/components/Link'
import { Aside, EmptyTableBody, Table, Td, Text, Th } from '@/components/ui'
import { path } from '@/constants/path'
import { color } from '@/constants/theme'
import { CombinedDefinition } from '@/models/combinedDefinition'

type Props = {
  combinedDefinition: CombinedDefinition
}

const sortTypes = ['asc', 'desc', 'none'] as const

type SortTypes = typeof sortTypes[number]

type SortState = {
  key: 'sourceName' | 'modules'
  sort: SortTypes
}

export const DefinitionSources: FC<Props> = ({ combinedDefinition }) => {
  const [sortState, setSortState] = useState<SortState>({ key: 'sourceName', sort: 'asc' })

  const setNextSortType = useCallback((key: SortState['key']) => {
    setSortState((prev) => {
      if (prev.key === key) {
       return {
          key,
          sort: sortTypes[(sortTypes.indexOf(prev.sort) + 1) % sortTypes.length],
        }
      } else {
        return { key, sort: 'asc' }
      }

    })
  }, [setSortState])

  const sources: CombinedDefinition['sources'] = useMemo(() => {
    let sorted = [...combinedDefinition.sources]

    if (sortState.sort === 'none') {
      return sorted
    }

    const ascString = (a: string, b: string) => {
      if (a > b) return 1
      if (a < b) return -1
      return 0
    }

    switch (sortState.key) {
      case 'sourceName': {
        sorted = sorted.sort((a, b) => ascString(a.sourceName, b.sourceName))
        break;
      }
      case 'modules': {
        sorted = sorted.sort((a, b) => ascString(a.modules.map((module) => module.moduleName).join('-'), b.modules.map((module) => module.moduleName).join('-')))
      }
    }

    if (sortState.sort === 'desc') {
      sorted = sorted.reverse()
    }

    return sorted
  }, [combinedDefinition.sources, sortState])

  return (
    <WrapperAside>
      <div style={{ overflow: 'clip' }}>
        <StyledTable fixedHead>
          <thead>
            <tr>
              <Th sort={sortState.key === 'sourceName' ? sortState.sort : 'none'} onSort={() => setNextSortType('sourceName')}>Source name</Th>
              <Th sort={sortState.key === 'modules' ? sortState.sort : 'none'} onSort={() => setNextSortType('modules')}>Modules</Th>
            </tr>
          </thead>
          {sources.length === 0 ? (
            <EmptyTableBody>
              <Text>お探しの条件に該当する項目はありません。</Text>
              <Text>別の条件をお試しください。</Text>
            </EmptyTableBody>
          ) : (
            <tbody>
              {sources.map((source) => (
                <tr key={source.sourceName}>
                  <Td>
                    <Link to={path.sources.show(source.sourceName)}>{source.sourceName}</Link>
                  </Td>
                  <Td>
                    {source.modules.map((module) => (
                      <Text key={module.moduleName} as="div">
                        <Link to={path.modules.show(module.moduleName)}>{module.moduleName}</Link>
                      </Text>
                    ))}
                  </Td>
                </tr>
              ))}
            </tbody>
          )}
        </StyledTable>
      </div>
    </WrapperAside>
  )
}

const WrapperAside = styled(Aside)`
  list-style: none;
  padding: 0;
  height: inherit;
  overflow-y: scroll;

  &&& {
    margin-top: 0;
  }
`

const StyledTable = styled(Table)`
  border-left: 1px ${color.BORDER} solid;
`
