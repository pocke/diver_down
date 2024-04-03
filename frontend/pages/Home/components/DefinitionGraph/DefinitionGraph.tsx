import { FC, useCallback, useState } from 'react'
import styled from 'styled-components'

import { Button, FaGearIcon, Heading, LineClamp, Section, Text } from '@/components/ui'
import { color } from '@/constants/theme'
import { CombinedDefinition } from '@/models/combinedDefinition'

import { ConfigureGraphOptionsDialog, GraphOptions } from './ConfigureGraphOptionsDialog'
import { ScrollableSvg } from './ScrollableSvg'

type Props = {
  combinedDefinition: CombinedDefinition
  graphOptions: GraphOptions
  setGraphOptions: React.Dispatch<React.SetStateAction<GraphOptions>>
}

type DialogType = 'configureGraphOptionsDiaglog'

export const DefinitionGraph: FC<Props> = ({ combinedDefinition, graphOptions, setGraphOptions }) => {
  const [visibleDialog, setVisibleDialog] = useState<DialogType | null>(null)

  const onClickCloseDialog = useCallback(() => {
    setVisibleDialog(null)
  }, [setVisibleDialog])

  return (
    <WrapperSection>
      <ConfigureGraphOptionsDialog
        isOpen={visibleDialog === 'configureGraphOptionsDiaglog'}
        onClickClose={onClickCloseDialog}
        graphOptions={graphOptions}
        setGraphOptions={setGraphOptions}
      />
      <FixedHeightHeading type="sectionTitle">
        <LineClamp>
          {combinedDefinition.titles.map((title, index) => (
            <BlockText key={index} size="XXS">
              {title}
            </BlockText>
          ))}
        </LineClamp>
        <Button
          size="s"
          square
          onClick={() => setVisibleDialog('configureGraphOptionsDiaglog')}
          prefix={<FaGearIcon alt="Open Options" />}
        >
          Open Graph Options
        </Button>
      </FixedHeightHeading>
      <FlexHeightSvgWrapper>
        <ScrollableSvg combinedDefinition={combinedDefinition} />
      </FlexHeightSvgWrapper>
    </WrapperSection>
  )
}

const WrapperSection = styled(Section)`
  display: flex;
  flex-direction: column;
  height: inherit;
  flex-grow: 1;
`

const FixedHeightHeading = styled(Heading)`
  min-height: 60px;
  overflow: scroll;
  border-bottom: ${color.BORDER} 1px solid;
`

const FlexHeightSvgWrapper = styled.div`
  height: calc(100% - 60px);
`

const BlockText = styled(Text)`
  display: block;
`
