import graphene

from ...core.tracing import traced_resolver
from ...menu import models
from ..channel import ChannelContext, ChannelQsContext
from ..core.validators import validate_one_of_args_is_in_query
from .types import Menu


@traced_resolver
def resolve_menu(info, channel, menu_id=None, name=None, slug=None):
    validate_one_of_args_is_in_query("id", menu_id, "name", name, "slug", slug)
    menu = None
    if menu_id:
        menu = graphene.Node.get_node_from_global_id(info, menu_id, Menu)
    if name:
        menu = models.Menu.objects.filter(name=name).first()
    if slug:
        menu = models.Menu.objects.filter(slug=slug).first()
    return ChannelContext(node=menu, channel_slug=channel) if menu else None


@traced_resolver
def resolve_menus(info, channel, **_kwargs):
    return ChannelQsContext(qs=models.Menu.objects.all(), channel_slug=channel)


@traced_resolver
def resolve_menu_items(info, **_kwargs):
    return models.MenuItem.objects.all()
