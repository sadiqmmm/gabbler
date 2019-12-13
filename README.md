# Gabbler

Gabbler is a customizable phoenix project for creating Reddit-Like websites. It is based on Phoenix and LiveView and provides the UI+Biz Logic to create and maintain Rooms (/r/..), sign on users and post content in a variety of ways. Most functionality and notifications to the user are presented in real time. Also provided is a service that tracks trends much like Twitter by keeping a sorted list of content organized by the Tags they were posted with.

Previously, Gabbler was a project called Smileys Pub, used to learn the Elixir ecosystem. This is a near complete refactor with a new goal to explore LiveView and practice/identify good practices and patterns for a site that can reach a high level of complexity or scale. As new ideas are explored, the codebase will adapt with a priority on setting good standards. It will also adapt quickly as LiveView evolves toward it's official release. There is in fact zero javascript beyond the hook to run LiveView and it will stay that way.

Feedback & suggestions quite appreciated!

Demo Site: [https://www.smileys.pub](https://www.smileys.pub)


# For Developers

Gabbler is going in the direction of a generic Reddit-like phoenix site where the querying backend (and later search indexing) can be swapped out and as many aspects of the site configurable as possible. That being said it is for a technical consumer and isn't meant yet to have anything like an admin interface to configure your options.

## Up and Running

The default dev setting is to have the Repo project alongside Gabbler Web. Everything else is pretty standard for a Phoenix project.

```
> cd project_dir
> git clone https://github.com/smileys-tavern/gabbler
> git clone https://github.com/smileys-tavern/gabbler_data.git
> cd gabbler
> mix deps.get
> cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
> mix ecto.migrate
> mix phx.server
```

You should be able to navigate to http://localhost:4000 now


## Update Translations/Gettext

```
> mix gettext.extract
> mix gettext.merge priv/gettext
```

## Design: Color Scheme

May be updated soon but for now just using the following pallete:

http://paletton.com/#uid=33B0u0kpQteg1DDl5vstnoow5jn


## Deployment

1. Ensure .deliver/config and rel/config.exs are up to date for your env and define a build server (see distillery and eDeliver docs)

2. Make sure Git repo is up to date

3. mix edeliver build release --mix-env=prod

4. mix edeliver deploy release prod --start-deploy