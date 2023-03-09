const axios = require('axios');

async function call_api(endpoint, params = {}) {
    const parameters = Object.keys(params).length > 0 ? '?' + new URLSearchParams(params).toString() : '';
    const response = await axios.get('https://v3.football.api-sports.io/' + endpoint + parameters, {
        headers: {
            'x-rapidapi-key': '2a1e24317ff7bb9098b445c21d5328ed'
        }
    });
    return response.data;
}

async function playersData(league, season, page = 1, players_data = []) {
    const players = await call_api('players', {league, season, page});
    players_data = players_data.concat(players.response);
    if (players.paging.current < players.paging.total) {
        page = players.paging.current + 1;
        if (page % 2 == 1) {
            await new Promise(resolve => setTimeout(resolve, 1000));
        }
        players_data = await playersData(league, season, page, players_data);
    }
    return players_data;
}

// Get all the teams from this competition
async function getTeams () {
const teams = await call_api('teams', {league: 71, season: 2022});
console.log(teams.response); // To display the results if necessary
}
getTeams();

// Get all the players from this competition
async function getPlayers () {
    const players = await playersData(71, 2022);
    console.log(players); // To display the results if necessary
}
//getPlayers();