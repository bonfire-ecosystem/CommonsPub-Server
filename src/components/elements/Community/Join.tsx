import React from 'react';
import styled from '../../../themes/styled';
import { Preferites } from '../Icons';
import { compose } from 'recompose';
import { graphql, OperationOption } from 'react-apollo';
const {
  joinCommunityMutation
} = require('../../../graphql/joinCommunity.graphql');
const {
  undoJoinCommunityMutation
} = require('../../../graphql/undoJoinCommunity.graphql');
import { Trans } from '@lingui/macro';
import gql from 'graphql-tag';

// const {
//   getJoinedCommunitiesQuery
// } = require('../../../graphql/getJoinedCommunities.graphql');

interface Props {
  joinCommunity: any;
  leaveCommunity: any;
  id: string;
  followed: boolean;
  externalId: string;
}

const withJoinCommunity = graphql<{}>(joinCommunityMutation, {
  name: 'joinCommunity'
  // TODO enforce proper types for OperationOption
} as OperationOption<{}, {}>);

const withLeaveCommunity = graphql<{}>(undoJoinCommunityMutation, {
  name: 'leaveCommunity'
  // TODO enforce proper types for OperationOption
} as OperationOption<{}, {}>);

const Join: React.SFC<Props> = ({
  joinCommunity,
  id,
  leaveCommunity,
  externalId,
  followed
}) => {
  if (followed) {
    return (
      <Span
        onClick={() =>
          leaveCommunity({
            variables: { communityId: id },
            update: (proxy, { data: { undoJoinCommunity } }) => {
              const fragment = gql`
                fragment Res on Community {
                  followed
                }
              `;
              let collection = proxy.readFragment({
                id: `Community:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res'
              });
              collection.followed = !collection.followed;
              // let joinedCommunities = proxy.readQuery({
              //   query: getJoinedCommunitiesQuery,
              //   variables: {
              //     limit: 15
              //   }
              // });
              // let index = joinedCommunities.me.user.joinedCommunities.edges.findIndex(
              //   e => e.node.id === externalId
              // );
              // console.log('qui');
              // console.log(index);
              // if (index === -1) {
              //   joinedCommunities.me.user.joinedCommunities.edges.unshift(
              //     collection
              //   );
              // }
              // joinedCommunities.me.user.joinedCommunities.edges.splice(
              //   index,
              //   1
              // );
              // console.log(index);
              // proxy.writeQuery({
              //   query: getJoinedCommunitiesQuery,
              //   variables: {
              //     limit: 15
              //   },
              //   data: joinedCommunities
              // });
              proxy.writeFragment({
                id: `Community:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res',
                data: collection
              });
            }
          })
            .then(res => {
              console.log(res);
            })
            .catch(err => console.log(err))
        }
      >
        <Trans>Leave</Trans>
      </Span>
    );
  } else {
    return (
      <Span
        onClick={() =>
          joinCommunity({
            variables: { communityId: id },
            update: (proxy, { data: { joinCommunity } }) => {
              const fragment = gql`
                fragment Res on Community {
                  followed
                }
              `;
              let collection = proxy.readFragment({
                id: `Community:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res'
              });
              collection.followed = !collection.followed;

              // let joinedCommunities = proxy.readQuery({
              //   query: getJoinedCommunitiesQuery,
              //   variables: {
              //     limit: 15
              //   }
              // })
              // if (joinedCommunities) {
              //   let index = joinedCommunities.me.user.joinedCommunities.edges
              //   .findIndex(e => e.node.id === externalId )
              //   if (index === -1) {
              //     joinedCommunities.me.user.joinedCommunities.edges.unshift(collection)
              //   }
              //   proxy.writeQuery({
              //     query: getJoinedCommunitiesQuery,
              //     variables: {
              //       limit: 15
              //     },
              //     data: joinedCommunities
              //   })
              // }

              proxy.writeFragment({
                id: `Community:${externalId}`,
                fragment: fragment,
                fragmentName: 'Res',
                data: collection
              });
            }
          })
            .then(res => {
              console.log(res);
            })
            .catch(err => console.log(err))
        }
      >
        <Preferites
          width={16}
          height={16}
          strokeWidth={2}
          color={'#1e1f2480'}
        />
        <Trans>Join</Trans>
      </Span>
    );
  }
};

const Span = styled.div`
  padding: 0px 10px;
  color: #1e1f2480;
  height: 40px;
  font-size: 15px;
  font-weight: 600;
  line-height: 40px;
  cursor: pointer;
  text-align: center;
  &:hover {
    color: ${props => props.theme.styles.colour.primaryAlt};
    & svg {
      color: ${props => props.theme.styles.colour.primaryAlt};
    }
  }
  & svg {
    margin-right: 8px;
    vertical-align: sub;
  }
`;

export default compose(
  withJoinCommunity,
  withLeaveCommunity
)(Join);
